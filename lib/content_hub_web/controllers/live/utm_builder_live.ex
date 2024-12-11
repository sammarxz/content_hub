defmodule ContentHubWeb.UTMBuilderLive do
  use ContentHubWeb, :live_view
  alias ContentHub.MetaFetcher

  @debounce_ms 500

  @impl true
  def mount(_params, _session, socket) do
    form =
      to_form(%{
        "url" => "",
        "source" => "",
        "medium" => "",
        "campaign" => "",
        "term" => "",
        "content" => ""
      })

    Process.send_after(self(), {:fetch_metadata, "marxz.me"}, @debounce_ms)

    {:ok,
     assign(socket,
       form: form,
       utm_link: nil,
       metadata: nil,
       loading_metadata: true,
       error_metadata: nil,
       qr_code_requested: false
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col lg:flex-row gap-4 sm:gap-8">
      <div class="flex-1 border text-card-foreground shadow-sm bg-white rounded-lg overflow-hidden mb-4 sm:mb-8">
        <div class="p-4 sm:p-6 flex flex-col h-full">
          <.form
            for={@form}
            phx-change="validate"
            phx-submit="preview"
            class="relative flex flex-col justify-between flex-grow space-y-2"
          >
            <div class="space-y-4">
              <div>
                <.label>Adicione a URL *</.label>
                <.input
                  type="text"
                  field={@form[:url]}
                  placeholder="exemplo.com"
                  phx-keyup="handle_url_keyup"
                  phx-key="Enter"
                  class="w-full"
                />
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <.label>Source</.label>
                  <.input type="text" field={@form[:source]} placeholder="e.g., google" />
                </div>
                <div>
                  <.label>Medium</.label>
                  <.input type="text" field={@form[:medium]} placeholder="e.g., cpc" />
                </div>
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <.label>Campaign</.label>
                  <.input type="text" field={@form[:campaign]} placeholder="e.g., summer_sale" />
                </div>
                <div>
                  <.label>Term</.label>
                  <.input type="text" field={@form[:term]} placeholder="e.g., running_shoes" />
                </div>
              </div>

              <div>
                <.label>Content</.label>
                <.input type="text" field={@form[:content]} placeholder="e.g., blue_banner" />
              </div>

              <div>
                <.label>UTM Link</.label>
                <div class="flex gap-2 mt-1 items-end">
                  <div class="flex-1" phx-hook="ClipboardHook" id="utm-link-container">
                    <.input
                      type="text"
                      name="utm_link"
                      id="utm_link"
                      value={@utm_link || "https://"}
                      readonly
                    />
                  </div>
                  <button
                    id="copy"
                    type="button"
                    data-to="#utm_link"
                    phx-hook="ClipboardHook"
                    class="h-9 w-9 bg-white shadow-sm border border-gray-300 rounded-md hover:bg-gray-50"
                    disabled={is_nil(@utm_link)}
                    aria-label="Copiar link UTM"
                  >
                    <.icon name="hero-clipboard" class="h-5 w-5" />
                  </button>
                </div>
              </div>
            </div>

            <div class="flex flex-col sm:flex-row justify-between mt-auto pt-4 gap-4">
              <.button type="button" aria-label="Gerar QR Code do link" phx-click="generate_qr_code" class="sm:w-auto">
                Gerar QR Code
              </.button>
              <.button
                type="button"
                phx-click="preview"
                phx-value-url={@form[:url].value}
                variant="outline"
                aria-label="Pré-visualizar Link"
                class="sm:w-auto"
              >
                Pré-visualizar <span class="text-gray-400 ml-2 hidden sm:inline">↵</span>
              </.button>
            </div>
          </.form>
        </div>
      </div>
      <div class="flex-1 border text-card-foreground shadow-sm bg-white rounded-lg overflow-hidden mb-4 sm:mb-8 cursor-pointer w-full">
        <div class="p-4 sm:p-6 flex flex-col h-full relative">
          <%!-- loading --%>
          <div
            :if={@loading_metadata}
            class="absolute bg-white inset-0 flex items-center justify-center z-10"
          >
            <div class="animate-pulse text-gray-500 flex items-center gap-2">
              <.icon name="hero-arrow-path" class="h-5 w-5 animate-spin" />
              <span>Carregando preview...</span>
            </div>
          </div>

          <%!-- Error --%>
          <div
            :if={@error_metadata}
            class="absolute bg-white inset-0 flex items-center justify-center"
          >
            <div class="flex flex-col items-center gap-3 text-sm text-red-600 text-center p-4">
              <.icon name="hero-exclamation-circle-mini" class="h-5 w-5" />
              <p><span class="block">Erro ao carregar preview:</span> {@error_metadata}</p>
            </div>
          </div>

          <%!-- Card Preview --%>
          <div :if={@metadata && !@error_metadata} class="flex flex-col h-full">
            <.live_component
              module={ContentHubWeb.SocialCardComponent}
              id="social-preview"
              metadata={@metadata}
            />
          </div>
        </div>
      </div>
    </div>
    <div :if={@qr_code_requested} class="flex justify-center mt-4">
      <.live_component module={ContentHubWeb.QRCodeComponent} id="qr-code" value={@utm_link} />
    </div>
    """
  end

  def handle_event("handle_url_keyup", %{"key" => "Enter", "value" => url}, socket) do
    if String.trim(url) != "" and url != socket.assigns[:last_preview_url] do
      Process.send_after(self(), {:fetch_metadata, url}, @debounce_ms)
      {:noreply, assign(socket, loading_metadata: true, last_preview_url: url)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("handle_url_keyup", _params, socket), do: {:noreply, socket}

  def handle_event("validate", params, socket) do
    form = to_form(params)
    utm_link = generate_utm_link(params)
    {:noreply, assign(socket, form: form, utm_link: utm_link)}
  end

  def handle_event("preview", %{"url" => url}, socket) do
    if String.trim(url) != "" and url != socket.assigns[:last_preview_url] do
      Process.send_after(self(), {:fetch_metadata, url}, @debounce_ms)
      {:noreply, assign(socket, loading_metadata: true, last_preview_url: url)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("copied", _params, socket) do
    {:noreply, put_flash(socket, :info, "Link copiado com sucesso!")}
  end

  @impl true
  def handle_event("error", %{"message" => message}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  @impl true
  def handle_event("generate_qr_code", _params, socket) do
    case socket.assigns.utm_link do
      nil ->
        {:noreply,
         put_flash(socket, :error, "Por favor, preencha a URL antes de gerar o QR Code.")}

      _ ->
        {:noreply, assign(socket, qr_code_requested: true)}
    end
  end

  def handle_event("close_qr_modal", _params, socket) do
    {:noreply, assign(socket, qr_code_requested: false)}
  end

  @impl true
  def handle_info({:fetch_metadata, url}, socket) when is_binary(url) do
    if String.trim(url) == "" do
      {:noreply, assign(socket, metadata: nil, loading_metadata: false, error_metadata: nil)}
    else
      case MetaFetcher.fetch(url) do
        {:ok, metadata} ->
          {:noreply,
           assign(socket,
             metadata: metadata,
             loading_metadata: false,
             error_metadata: nil
           )}

        {:error, reason} ->
          {:noreply,
           assign(socket,
             metadata: nil,
             loading_metadata: false,
             error_metadata: error_message(reason)
           )}
      end
    end
  end

  defp generate_utm_link(params) do
    base_url = params["url"] |> to_string() |> String.trim()

    if base_url == "",
      do: nil,
      else: build_utm_link(base_url, params)
  end

  defp build_utm_link(base_url, params) do
    utm_params =
      [
        {"source", params["source"]},
        {"medium", params["medium"]},
        {"campaign", params["campaign"]},
        {"term", params["term"]},
        {"content", params["content"]}
      ]
      |> Enum.reject(fn {_, value} -> is_nil(value) || value == "" end)
      |> Enum.map(fn {key, value} -> {"utm_#{key}", value} end)
      |> URI.encode_query()

    base_url = if String.starts_with?(base_url, "http"), do: base_url, else: "https://#{base_url}"

    case utm_params do
      "" -> base_url
      params -> "#{base_url}?#{params}"
    end
  end

  defp error_message(:timeout), do: "Tempo limite excedido ao carregar a página"
  defp error_message(:invalid_url), do: "URL inválida"
  defp error_message(:not_found), do: "Página não encontrada"
  defp error_message(:domain_not_found), do: "Domínio não encontrado"
  defp error_message(:connection_failed), do: "Não foi possível conectar ao servidor"
  defp error_message(:service_unavailable), do: "Serviço temporariamente indisponível"
  defp error_message(:parse_error), do: "Erro ao processar a página"
  defp error_message(:unexpected_error), do: "Erro inesperado ao carregar o preview"
  defp error_message(_), do: "Não foi possível carregar o preview da página"
end
