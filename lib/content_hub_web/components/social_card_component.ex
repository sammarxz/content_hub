defmodule ContentHubWeb.SocialCardComponent do
  use ContentHubWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="space-y-4 flex flex-col h-full">
      <%= if @metadata.image do %>
        <img src={@metadata.image} alt="" class="w-full h-48 object-cover rounded-lg" loading="lazy" />
      <% else %>
        <div class="w-full h-48 object-cover rounded-lg">
          <.icon name="hero-photo" class="h-12 w-12 text-gray-300" />
        </div>
      <% end %>
      <div class="flex items-center space-x-2">
        <%= if @metadata.favicon do %>
          <img src={@metadata.favicon} alt="" class="h-4 w-4" />
        <% end %>
        <p class="text-sm text-gray-500 truncate">{@metadata.url}</p>
      </div>
      <h3 class="text-lg font-semibold">
        {@metadata.title || "Sem título"}
      </h3>
      <p class="text-sm text-gray-700 flex-grow">
        {@metadata.description || "Sem descrição"}
      </p>
      <div class="mt-auto pt-4">
        <a
          href={@metadata.url}
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2 w-full"
        >
          Visite {String.replace(@metadata.url, ~r/^https?:\/\//, "")}
        </a>
      </div>
    </div>
    """
  end
end
