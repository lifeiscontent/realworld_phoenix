# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
- Phoenix Realworld implementation inspired by the RealWorld spec (https://github.com/gothinkster/realworld)
- LiveView-only implementation (no JSON API) for a Medium.com clone

## Common Development Commands

### Environment Setup
- `asdf set erlang <version>` - Set Erlang version for project (modern asdf command)
- `asdf set elixir <version>` - Set Elixir version for project (modern asdf command)
- Note: `asdf local` is deprecated, use `asdf set` instead

### Project Setup
- `mix phx.new . --app realworld` - Generate Phoenix project with LiveView
- `mix deps.get` - Install dependencies
- `mix ecto.create` - Create database
- `mix ecto.migrate` - Run migrations

### Authentication Setup (phx.gen.auth)
- `mix phx.gen.auth Accounts User users --hashing-lib argon2` - Generate auth system with argon2
- Creates Accounts context with User schema
- Provides session-based authentication with LiveView support
- Includes user registration, login, password reset, email confirmation
- Authentication plugs: `fetch_current_user`, `require_authenticated_user`, `redirect_if_user_is_authenticated`

### Development
- `mix phx.server` or `iex -S mix phx.server` - Start Phoenix server
- `mix test` - Run all tests
- `mix test path/to/test.exs` - Run specific test file
- `mix test path/to/test.exs:42` - Run specific test at line 42
- `mix format` - Format code according to Elixir standards
- `mix credo` - Run static code analysis (if added)

### Database
- `mix ecto.gen.migration migration_name` - Generate new migration
- `mix ecto.rollback` - Rollback last migration
- `mix ecto.reset` - Drop, create, and migrate database

## Architecture Guidelines

### Directory Structure
- `lib/realworld/` - Core business logic and contexts
- `lib/realworld_web/` - Web layer (controllers, views, router)
- `lib/realworld_web/controllers/` - API controllers
- `test/` - Test files mirroring lib structure
- `priv/repo/migrations/` - Database migrations

### LiveView Implementation Approach
- This is a LiveView-only implementation (no JSON API)
- All features implemented using Phoenix LiveView
- No JWT authentication needed (using session-based auth)
- No CORS configuration needed (same-origin only)

### Phoenix Patterns
- Use Contexts for business logic (e.g., `Accounts`, `Blog`)
- Keep LiveViews thin - delegate to contexts
- Use Ecto changesets for validation
- Use Phoenix's built-in session authentication
- Use Phoenix PubSub for real-time updates

## Authorization System

### Policy Module (`Realworld.Policies`)
- Central authorization module using pattern matching
- Admin users have full access (role: "admin")
- Users can manage their own resources
- Article visibility rules: draft (owner only), published (public), archived (owner/admin)

### Authorization in Controllers
- Use `RealworldWeb.Plugs.Authorize` plug
- Example: `plug RealworldWeb.Plugs.Authorize, :admin when action in [:index, :delete]`

### Authorization in LiveView
- Use `on_mount RealworldWeb.AuthLive` for authentication (calls with :default)
- Must implement `on_mount(:default, ...)` when using bare module name
- Use `on_mount {RealworldWeb.AuthLive, :require_admin}` for admin-only pages
- Check authorization with `Policies.authorize(action, user, resource)`
- on_mount/4 must return `{:cont, socket}` or `{:halt, socket}`

### Handling User Associations in Forms
- Set user_id when creating new structs in parent LiveView: `%Article{user_id: current_user.id}`
- Use hidden input in forms: `<.input field={@form[:user_id]} type="hidden" />`
- This is more idiomatic than modifying params in the save handler
- The hidden input will automatically use the value from the struct passed to the form
- Always validate associations in changesets for security

### Form Security and Authorization
- Add policy checks for form params: `authorize(:create_article, user, %{"user_id" => param_user_id})`
- Compare string params with integer IDs using `to_string(user_id) == param_user_id`
- Pass current_user to LiveView components that need authorization
- Show form validation errors using `Ecto.Changeset.add_error(:field, "message")`
- Set `Map.put(:action, :validate)` on changeset to display errors
- Don't use base errors - add errors directly to the relevant field for better UX

### User Roles
- Default role: "user"
- Admin role: "admin"
- Add role field to users table with migration

### Testing Approach
- Write controller tests for API endpoints
- Write context tests for business logic
- Use ExMachina for test factories
- Test both success and error cases
- Verify proper status codes and response formats

## Code Style
- Follow standard Elixir formatting (enforced by `mix format`)
- Use pattern matching extensively
- Prefer function clauses over conditionals
- Use `with` for complex operations with multiple steps
- Document public functions with @doc

## Comments System Implementation
- Comments belong to both User and Article (many-to-many relationship)
- Use `mix phx.gen.live` to generate resources with associations
- Integrate comments into article show page rather than separate routes
- Use LiveView streams for real-time comment updates
- Preload associations when fetching records: `Repo.preload(:user)`

### LiveView Streams
- Cannot use `Enum.empty?` on streams - they're not enumerable
- Use CSS `:only-child` selector to handle empty streams
- Pattern: `<p id="items-empty" class="only:block hidden">No items</p>`
- Parent container must have `phx-update="stream"`
- Each stream item must have unique DOM id

### Hidden Inputs in Forms
- Add "hidden" to the input type values in core_components.ex
- Create a specific input/1 function clause for type="hidden"
- Hidden inputs still need error display capability
- Use `<.input field={@form[:user_id]} type="hidden" />` in forms

## Memory Management
- Always check docs first before working on anything new, once you've checked the docs, update your memories based on how memory works here: https://docs.anthropic.com/en/docs/claude-code/memory

## Bodyguard-like Authorization Pattern
- Use `Policies.permit?/3` for boolean authorization checks instead of custom functions
- `permit?` is a wrapper around `authorize` that returns true/false
- Example: `Policies.permit?(:create_comment, current_user, article)`
- This pattern is more consistent and matches Bodyguard's API design
- Assign authorization results to socket: `assign(:can_comment?, Policies.permit?(:create_comment, current_user, article))`

## Form Reset in LiveView
- To clear a form after submission, pass explicit empty values to the changeset
- `Blog.change_comment(%{})` won't clear fields - Ecto preserves existing values when no params given
- `Blog.change_comment(%{"content" => ""})` will clear the content field - empty strings are converted to nil
- This is documented behavior: "When applying changes using cast/4, an empty value will be automatically converted to the field's default value"
- Always pass explicit empty strings for fields you want to clear in forms

## Code Organization
- Don't mix business logic together e.g. time_zone and user might be related, but do not directly overlap
- Create separate modules for distinct concerns (e.g., TimeZoneLive for timezone handling, AuthLive for authentication)

## Timezone Handling
- Users have a `time_zone` field that stores their preferred timezone
- Timezone is captured from browser on registration and updated on each login
- Use `on_mount RealworldWeb.TimeZoneLive` in LiveViews that need timezone support
- TimeZoneLive assigns `:time_zone` to socket based on user preference or browser timezone
- Format timestamps using `format_datetime/2` function that converts UTC to user's local time

## Current Implementation Status
### Completed Features:
- User authentication (registration, login, logout, password reset)
- User roles (user/admin) with authorization policies
- Articles with CRUD operations and status (draft/published/archived)
- Comments system with real-time updates via Phoenix PubSub
- Timezone support for displaying local times

### Pending Features (LiveView implementation):
- User profiles (username, bio, image)
- Following system
- Article favorites/likes
- Tags system
- Article slugs (currently using numeric IDs)
- Feed functionality (global and personalized)
- Pagination support