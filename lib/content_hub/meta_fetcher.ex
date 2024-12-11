defmodule ContentHub.MetaFetcher do
  @moduledoc """
  Módulo responsável por buscar e processar metadados de URLs.
  """

  use GenServer
  require Logger

  @request_timeout 5_000  # 5 segundos
  @genserver_timeout 10_000  # 10 segundos

  # Cliente API
  def start_link(opts \\ []) do
    Logger.info("Starting MetaFetcher...")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Busca metadados de uma URL.
  """
  def fetch(url) when is_binary(url) do
    Logger.debug("Fetching metadata for URL: #{url}")
    try do
      GenServer.call(__MODULE__, {:fetch, url}, @genserver_timeout)
    catch
      :exit, {:timeout, _} ->
        Logger.warn("GenServer timeout while fetching metadata for: #{url}")
        {:error, :timeout}
      :exit, {:noproc, _} ->
        Logger.error("MetaFetcher process not available")
        {:error, :service_unavailable}
      kind, reason ->
        Logger.error("Unexpected error in fetch: #{inspect({kind, reason})}")
        {:error, :unexpected_error}
    end
  end
  def fetch(_), do: {:error, :invalid_url}

  # Callbacks do Server
  @impl true
  def init(_opts) do
    Logger.info("Initializing MetaFetcher state")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:fetch, url}, _from, state) do
    Logger.debug("Handling fetch request for URL: #{url}")
    result = do_fetch(url)
    {:reply, result, state}
  end

  # Funções privadas
  defp do_fetch(url) do
    normalized_url = normalize_url(url)
    Logger.debug("Making HTTP request to normalized URL: #{normalized_url}")

    request = Finch.build(:get, normalized_url)

    case Finch.request(request, ContentHub.Finch, receive_timeout: @request_timeout) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        Logger.debug("Successful response from #{normalized_url}")
        case Floki.parse_document(body) do
          {:ok, document} ->
            metadata = extract_metadata(document, normalized_url)
            {:ok, metadata}

          error ->
            Logger.error("Failed to parse document: #{inspect(error)}")
            {:error, :parse_error}
        end

      {:ok, %{status: 404}} ->
        Logger.warn("URL not found: #{normalized_url}")
        {:error, :not_found}

      {:ok, %{status: status, headers: headers}} when status in [301, 302, 303, 307, 308] ->
        case List.keyfind(headers, "location", 0) do
          {_, redirect_url} ->
            Logger.debug("Following redirect to: #{redirect_url}")
            do_fetch(redirect_url)
          nil ->
            Logger.warn("Redirect without location header from: #{normalized_url}")
            {:error, :invalid_redirect}
        end

      {:ok, %{status: status}} ->
        Logger.warn("Unexpected status code #{status} for: #{normalized_url}")
        {:error, :invalid_response}

      {:error, %{reason: :timeout}} ->
        Logger.warn("Request timeout for: #{normalized_url}")
        {:error, :timeout}

      {:error, %Mint.TransportError{reason: :nxdomain}} ->
        Logger.warn("Domain not found: #{normalized_url}")
        {:error, :domain_not_found}

      {:error, %Mint.TransportError{reason: reason}} ->
        Logger.warn("Transport error (#{reason}) for: #{normalized_url}")
        {:error, :connection_failed}

      error ->
        Logger.error("Request failed: #{inspect(error)}")
        {:error, :request_failed}
    end
  rescue
    error ->
      Logger.error("Unexpected error in do_fetch: #{inspect(error)}")
      {:error, :unexpected_error}
  end

  defp normalize_url(url) do
    trimmed_url = String.trim(url)
    cond do
      String.starts_with?(trimmed_url, "http://") -> trimmed_url
      String.starts_with?(trimmed_url, "https://") -> trimmed_url
      # Verifica se tem caracteres inválidos comuns
      String.contains?(trimmed_url, [" ", "\t", "\n"]) ->
        {:error, :invalid_url}
      # Verifica comprimento mínimo e se contém pelo menos um ponto
      byte_size(trimmed_url) < 4 or not String.contains?(trimmed_url, ".") ->
        {:error, :invalid_url}
      true -> "https://#{trimmed_url}"
    end
  end

  defp extract_metadata(document, url) do
    %{
      url: url,
      title: extract_meta(document, "og:title") || extract_title(document),
      description: extract_meta(document, "og:description") || extract_meta(document, "description"),
      image: extract_meta(document, "og:image"),
      favicon: extract_favicon(document, url)
    }
  end

  defp extract_meta(document, property) do
    Floki.find(document, ~s{meta[property="#{property}"]})
    |> get_content()
    |> List.first() ||
      Floki.find(document, ~s{meta[name="#{property}"]})
      |> get_content()
      |> List.first()
  end

  defp extract_title(document) do
    Floki.find(document, "title")
    |> Floki.text()
    |> case do
      "" -> nil
      title -> String.trim(title)
    end
  end

  defp extract_favicon(document, base_url) do
    favicon_path =
      Floki.find(document, ~s{link[rel="icon"]}) ++
        Floki.find(document, ~s{link[rel="shortcut icon"]})
      |> get_href()
      |> List.first()

    case favicon_path do
      nil -> nil
      path -> build_absolute_url(base_url, path)
    end
  end

  defp get_content(elements) do
    Enum.map(elements, fn elem ->
      Floki.attribute(elem, "content")
      |> List.first()
    end)
  end

  defp get_href(elements) do
    Enum.map(elements, fn elem ->
      Floki.attribute(elem, "href")
      |> List.first()
    end)
  end

  defp build_absolute_url(base_url, path) do
    case URI.merge(base_url, path) do
      %URI{} = uri -> URI.to_string(uri)
      _ -> nil
    end
  rescue
    _ -> nil
  end
end
