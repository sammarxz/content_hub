defmodule ContentHubWeb.QRCodeComponent do
  use ContentHubWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="qr-modal-overlay" phx-click="close_qr_modal">
      <div class="qr-modal-container" phx-click-away="close_qr_modal">
        <div class="qr-modal-content">
          <form phx-target={@myself}>
            <div class="qr-preview">
              {raw(elem(@svg_data, 1))}
            </div>
            <.button type="button" class="w-full" phx-click="download" phx-target={@myself}>
              <.icon name="hero-arrow-down-tray" class="w-4 h-4 mr-2" /> Download QR
            </.button>
          </form>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(svg_data: generate_qr(assigns.value))}
  end

  defp generate_qr(value) do
    svg_settings = %QRCode.Render.SvgSettings{
      structure: :readable
    }

    value
    |> QRCode.create()
    |> QRCode.render(:svg, svg_settings)
  end

  def handle_event("download", _params, socket) do
    filename = "qr-code.svg"
    {_type, svg_content} = socket.assigns.svg_data

    {:noreply,
     socket
     |> push_event("file:download", %{
       data: svg_content,
       filename: filename,
       mime_type: "image/svg+xml"
     })}
  end
end
