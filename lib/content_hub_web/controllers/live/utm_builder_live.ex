defmodule ContentHubWeb.UTMBuilderLive do
  use ContentHubWeb, :live_view

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

    {:ok, assign(socket, form: form, utm_link: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col lg:flex-row gap-4 sm:gap-8">
      <div class="border text-card-foreground shadow-sm bg-white rounded-lg overflow-hidden mb-4 sm:mb-8 flex-1 w-full">
        <div class="p-4 sm:p-6 flex flex-col h-full">
          <.form
            for={@form}
            phx-change="validate"
            phx-submit="generate"
            class="space-y-4 sm:space-y-6 flex-grow"
          >
            <div>
              <.label>Adicione a URL *</.label>
              <.input type="text" field={@form[:url]} placeholder="exemplo.com" class="w-full" />
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <.label>Source</.label>
                <.input type="text" field={@form[:source]} placeholder="google" />
              </div>
              <div>
                <.label>Medium</.label>
                <.input type="text" field={@form[:medium]} placeholder="cpc" />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <.label>Campaign</.label>
                <.input type="text" field={@form[:campaign]} placeholder="summer_sale" />
              </div>
              <div>
                <.label>Term</.label>
                <.input type="text" field={@form[:term]} placeholder="running_shoes" />
              </div>
            </div>

            <div>
              <.label>Content</.label>
              <.input type="text" field={@form[:content]} placeholder="blue_banner" />
            </div>

            <div class="mt-4">
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
                  class="px-3 py-2 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
                  disabled={is_nil(@utm_link)}
                >
                  <.icon name="hero-clipboard" class="h-5 w-5 text-gray-500" />
                </button>
              </div>
            </div>

            <div class="flex gap-4">
              <.button type="submit" class="flex-1">Gerar QR Code</.button>
              <.button type="button" class="flex-1" variant="outline">Pré visualizar</.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("validate", params, socket) do
    form = to_form(params)
    utm_link = generate_utm_link(params)

    {:noreply, assign(socket, form: form, utm_link: utm_link)}
  end

  def handle_event("generate", params, socket) do
    utm_link = generate_utm_link(params)
    {:noreply, assign(socket, utm_link: utm_link)}
  end

  @impl true
  def handle_event("copied", _params, socket) do
    {:noreply, put_flash(socket, :info, "Link copiado com sucesso!")}
  end

  @impl true
  def handle_event("error", %{"message" => message}, socket) do
    {:noreply, put_flash(socket, :error, message)}
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
end
