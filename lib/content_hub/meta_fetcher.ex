defmodule ContentHub.MetaFetcher do
  use GenServer

  @request_timeout 5_000
  @genserver_timeout 10_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def fetch(url) when is_binary(url) do
    try do
      GenServer.call(__MODULE__, {:fetch, url}, @genserver_timeout)
    catch
      :exit, {:timeout, _} -> {:error, :timeout}
      :exit, {:noproc, _} -> {:error, :service_unavailable}
      _kind, _reason -> {:error, :unexpected_error}
    end
  end

  def fetch(_), do: {:error, :invalid_url}

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:fetch, url}, _from, state) do
    result = do_fetch(url)
    {:reply, result, state}
  end

  defp do_fetch(url) do
    normalized_url = normalize_url(url)
    request = Finch.build(:get, normalized_url)

    case Finch.request(request, ContentHub.Finch, receive_timeout: @request_timeout) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        case Floki.parse_document(body) do
          {:ok, document} ->
            metadata = extract_metadata(document, normalized_url)
            {:ok, metadata}

          _error ->
            {:error, :parse_error}
        end

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status, headers: headers}} when status in [301, 302, 303, 307, 308] ->
        case List.keyfind(headers, "location", 0) do
          {_, redirect_url} -> do_fetch(redirect_url)
          nil -> {:error, :invalid_redirect}
        end

      {:ok, %{status: _status}} ->
        {:error, :invalid_response}

      {:error, %{reason: :timeout}} ->
        {:error, :timeout}

      {:error, %Mint.TransportError{reason: :nxdomain}} ->
        {:error, :domain_not_found}

      {:error, %Mint.TransportError{reason: _reason}} ->
        {:error, :connection_failed}

      _error ->
        {:error, :request_failed}
    end
  rescue
    _error -> {:error, :unexpected_error}
  end

  defp normalize_url(url) do
    trimmed_url = String.trim(url)

    cond do
      String.starts_with?(trimmed_url, "http://") ->
        trimmed_url

      String.starts_with?(trimmed_url, "https://") ->
        trimmed_url

      String.contains?(trimmed_url, [" ", "\t", "\n"]) ->
        {:error, :invalid_url}

      byte_size(trimmed_url) < 4 or not String.contains?(trimmed_url, ".") ->
        {:error, :invalid_url}

      true ->
        "https://#{trimmed_url}"
    end
  end

  defp extract_metadata(document, url) do
    %{
      url: url,
      title: extract_meta(document, "og:title") || extract_title(document),
      description:
        extract_meta(document, "og:description") || extract_meta(document, "description"),
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
      (Floki.find(document, ~s{link[rel="icon"]}) ++
         Floki.find(document, ~s{link[rel="shortcut icon"]}))
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
