# credo:disable-for-this-file /Credo\.Check\.Refactor\./
defmodule Mix.Tasks.Generate.Forcex do
  use Mix.Task

  @recursive false

  def run(_) do
    {:ok, _} = Application.ensure_all_started(:forcex)

    client = Forcex.Client.login()

    case client do
      %{access_token: nil} ->
        IO.puts("Invalid configuration/credentials. Cannot generate SObjects.")

      _ ->
        generate_modules(client)
    end

    :ok
  end

  defp generate_modules(client) do
    app_dir = File.cwd!
    app_name = Path.basename(app_dir)

    sobject_files_path = Path.join([app_dir, "lib", app_name, "forcex", "sobject"])

    IO.puts("creating #{sobject_files_path}")
    File.mkdir_p!(sobject_files_path)

    client = Forcex.Client.locate_services(client)

    sobjects =
      client
      |> Forcex.describe_global()
      |> Map.get(:sobjects)
      |> filter_sobjects()

    for sobject <- sobjects do
      sobject_file_path = Path.join([sobject_files_path, "#{Macro.underscore(sobject.name)}.ex"])
      sobject_code = sobject
      |> generate_module(client)
      |> IO.inspect(label: "quote output")
      |> Macro.to_string()
      |> IO.inspect(label: "macroed string")

      IO.puts("Writing #{sobject_file_path}")
      File.write(sobject_file_path, sobject_code, [:write])
    end
  end

  defp filter_sobjects(all_sobjects), do: filter_sobjects(all_sobjects, config()[:sobjects])
  defp filter_sobjects(all_sobjects, []), do: all_sobjects
  defp filter_sobjects(all_sobjects, nil), do: all_sobjects

  defp filter_sobjects(all_sobjects, selected_sobjects),
    do: Enum.filter(all_sobjects, &sobject_selected?(&1, selected_sobjects))

  defp sobject_selected?(sobject, selected_sobjects), do: sobject.name in selected_sobjects

  defp generate_module(sobject, client) do
    name = sobject.name
    urls = sobject.urls
    describe_url = urls.describe
    sobject_url = urls.sobject
    row_template_url = urls.rowTemplate
    full_description = Forcex.describe_sobject(name, client)

    quote location: :keep do
      defmodule unquote(Module.concat(Forcex.SObject, name)) do
        def describe(client) do
          unquote(describe_url)
          |> Forcex.get(client)
        end

        def basic_info(client) do
          unquote(sobject_url)
          |> Forcex.get(client)
        end

        def create(sobject, client) when is_map(sobject) do
          unquote(sobject_url)
          |> Forcex.post(sobject, client)
        end

        def update(id, changeset, client) do
          unquote(row_template_url)
          |> String.replace("{ID}", id)
          |> Forcex.patch(changeset, client)
        end

        def delete(id, client) do
          unquote(row_template_url)
          |> String.replace("{ID}", id)
          |> Forcex.delete(client)
        end

        def get(id, client) do
          unquote(row_template_url)
          |> String.replace("{ID}", id)
          |> Forcex.get(client)
        end

        def deleted_between(start_date, end_date, client)
            when is_binary(start_date) and is_binary(end_date) do
          params = %{"start" => start_date, "end" => end_date} |> URI.encode_query()

          (unquote(sobject_url) <> "/deleted?#{params}")
          |> Forcex.get(client)
        end

        def deleted_between(start_date, end_date, client) do
          deleted_between(
            Timex.format!(start_date, "{ISO8601z}"),
            Timex.format!(end_date, "{ISO8601z}"),
            client
          )
        end

        def updated_between(start_date, end_date, client)
            when is_binary(start_date) and is_binary(end_date) do
          params = %{"start" => start_date, "end" => end_date} |> URI.encode_query()

          (unquote(sobject_url) <> "/updated?#{params}")
          |> Forcex.get(client)
        end

        def updated_between(start_date, end_date, client) do
          updated_between(
            Timex.format!(start_date, "{ISO}"),
            Timex.format!(end_date, "{ISO}"),
            client
          )
        end

        def get_blob(id, field, client) do
          (unquote(row_template_url) <> "/#{field}")
          |> String.replace("{ID}", id)
          |> Forcex.get(client)
        end

        def by_external(field, value, client) do
          (unquote(sobject_url) <> "/#{field}/#{value}")
          |> Forcex.get(client)
        end

        def upsert_by_external(sobject, field, value, client) when is_map(sobject) do
          (unquote(sobject_url) <> "/#{field}/#{value}")
          |> Forcex.patch(sobject, client)
        end
      end
    end
  end

  defp docs_for_field(%{name: name, type: type, label: label, picklistValues: values})
       when type in [:picklist, :multipicklist] do
    """
    * `#{name}` - `#{type}`, #{label}
    #{for value <- values, do: docs_for_picklist_values(value)}
    """
  end

  defp docs_for_field(%{name: name, type: type, label: label}) do
    "* `#{name}` - `#{type}`, #{label}\n"
  end

  defp docs_for_picklist_values(%{value: value, active: true}) do
    "     * `#{value}`\n"
  end

  defp docs_for_picklist_values(_), do: ""

  defp config, do: Application.get_env(:forcex, Forcex.Client)
end
