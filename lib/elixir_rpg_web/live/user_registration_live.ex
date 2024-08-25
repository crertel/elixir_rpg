defmodule ElixirRpgWeb.UserRegistrationLive do
  use ElixirRpgWeb, :live_view

  alias ElixirRpg.Accounts
  alias ElixirRpg.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign(faction: nil)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-row h-screen w-screen justify-center">
      <!-- Description -->
      <div class="flex flex-col justify-center items-center w-full">
        <div class="w-3/4 justify-center items-center">
          <div :if={is_nil(@faction)}>
            <h1 class="text-2xl text-zinc-300 text-center">Select your faction.</h1>
          </div>
          <div :if={!is_nil(@faction)} class="flex flex-col items-center">
            <div>
              <h2 class="font-bold text-3xl text-zinc-600 text-center">
                <%= @faction.display_name %>
              </h2>
            </div>
            <div>
              <p class="font-bold text-2xl text-zinc-200 text-center"><%= @faction.description %></p>
            </div>
            <img class="w-[400px]" src={@faction.selection_art} />
            <div>
              <p class="font-bold text-2xl text-zinc-200 text-center  p-10">
                <%= @faction.self_description %>
              </p>
            </div>
          </div>
        </div>
      </div>
      <!-- Creation-->
      <div class="flex flex-col justify-center items-center w-full">
        <div class="w-1/2 justify-center items-center">
          <.header class="text-center">
            Register for an account
            <:subtitle>
              (Already have an acconut?
              <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
                Log in
              </.link>
              to your account now.)
            </:subtitle>
          </.header>

          <.simple_form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/log_in?_action=registered"}
            method="post"
          >
            <.error :if={@check_errors}>
              Oops, something went wrong! Please check the errors below.
            </.error>

            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:password]} type="password" label="Password" required />
            <.input
              field={@form[:faction]}
              type="select"
              label="Pick a faction"
              options={ElixirRpg.Factions.factions()}
              required
            />

            <:actions>
              <.button phx-disable-with="Creating account..." class="w-full">
                Create an account
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = Map.put(user_params, "display_name", user_params["email"])

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)

    case Ecto.Changeset.fetch_change(changeset, :faction) do
      {:ok, new_faction} ->
        {:noreply,
         socket
         |> assign(:faction, new_faction |> ElixirRpg.Factions.faction_info())
         |> assign_form(Map.put(changeset, :action, :validate))}

      _ ->
        {:noreply, socket |> assign_form(Map.put(changeset, :action, :validate))}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
