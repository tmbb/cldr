if Code.ensure_loaded?(Flow) do
  defmodule Mix.Tasks.Cldr.Consolidate do
    @moduledoc """
    Mix task to consolidate the cldr data into a set of files, one file per
    CLDR locale.
    """

    use Mix.Task

    @shortdoc "Consolidate cldr json data into a single per-locale set of files"

    def run(_) do
      Cldr.Consolidate.consolidate_locales()
    end
  end
end

