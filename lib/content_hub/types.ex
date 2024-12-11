defmodule ContentHub.Types do
  @moduledoc """
  Define os tipos de dados utilizados na aplicação.
  """

  @type utm_params :: %{
    url: String.t(),
    source: String.t(),
    medium: String.t(),
    campaign: String.t(),
    term: String.t(),
    content: String.t()
  }

  @type meta_preview :: %{
    title: String.t(),
    description: String.t(),
    image: String.t(),
    favicon: String.t()
  }

  @type stored_link :: %{
    id: String.t(),
    utm_params: utm_params(),
    meta_preview: meta_preview(),
    created_at: DateTime.t()
  }
end