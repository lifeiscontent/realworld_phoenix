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

### Query Scoping (Bodyguard-style)
- Use `Policies.scope/3` or `Policies.scope/4` to filter queries based on user permissions
- Implements authorization at the query level to ensure users only see data they're authorized to access
- Example: `Article |> Policies.scope(:list_articles, user) |> Repo.all()`
- Scopes are defined in the Policies module alongside other authorization rules
- This approach keeps authorization logic centralized and reusable across contexts

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

## Documentation First Approach
- ALWAYS read the official documentation before implementing features
- DO NOT make up conventions or patterns - use what's documented
- Check Phoenix, LiveView, and Ecto docs for proper patterns
- Update CLAUDE.md with learned patterns from documentation

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

## Database Fields and Validation
- Required fields in the database (null: false) should NEVER have fallbacks in the UI
- If a field is required, trust that it exists - don't add defensive checks like `@user.username || @user.email`
- Username is a required field for all users and must be unique
- Username validation: URL-safe characters only (letters, numbers, hyphens, underscores)
- ALWAYS update changesets when adding new fields - if you add a field to the schema, add it to the relevant changeset's cast/3 call
- When implementing file uploads or any form that updates database fields, ensure the changeset accepts those fields

## Timezone Handling
- Users have a `time_zone` field that stores their preferred timezone
- Timezone is captured from browser on registration and updated on each login
- Use `on_mount RealworldWeb.TimeZoneLive` in LiveViews that need timezone support
- TimeZoneLive assigns `:time_zone` to socket based on user preference or browser timezone
- Format timestamps using `format_datetime/2` function that converts UTC to user's local time

## Git Workflow
- ALWAYS commit completed features before starting new ones
- Create logical, atomic commits for each feature
- Don't mix multiple features in a single commit
- Run `git status` to check what needs to be committed
- Write clear commit messages that describe what was implemented

## Code Cleanup and Refactoring
- When changing how resources are accessed (e.g., from ID to slug/username), update ALL related code
- Remove or update functions that become obsolete after refactoring
- Don't leave unused functions in the codebase unless they're still needed for tests
- Check for all usages before removing functions using grep/search tools
- When using Phoenix.Param to change URL parameters, ensure all links and route handlers are updated

## Many-to-Many Associations and Join Tables
- When using `@primary_key false` on join tables, you CANNOT use `Repo.delete` - use `Repo.delete_all` with a query instead
- Ecto's `put_assoc` does NOT automatically add timestamps to join tables
- For join tables with timestamps, manually insert with `Repo.insert_all` and include timestamp fields
- Example: `Repo.insert_all("article_tags", [%{article_id: 1, tag_id: 1, inserted_at: DateTime.utc_now()}])`

## LiveView Component Communication
- When a LiveComponent sends messages to its parent using `notify_parent`, the parent MUST have a matching `handle_info/2` clause
- FormComponent pattern: `send(self(), {__MODULE__, {:saved, resource}})` requires parent to handle `{ComponentModule, {:saved, resource}}`
- Always check that parent LiveViews handle component messages when using the notify pattern

## Current Implementation Status
### Completed Features:
- User authentication (registration, login, logout, password reset)
- User roles (user/admin) with authorization policies
- Articles with CRUD operations and status (draft/published/archived)
- Comments system with real-time updates via Phoenix PubSub
- Timezone support for displaying local times
- User profiles (username, bio, image with file uploads)
- Article slugs using Phoenix.Param (SEO-friendly URLs)

### Completed Features (continued):
- Feed functionality (global and personalized) with infinite scroll
- Cursor-based pagination with LiveView's phx-viewport-bottom
- Tag filtering for both global and following feeds
- User following system
- Article favorites/likes system

### Pending Features (LiveView implementation):
- Article search functionality
- User notifications system

## Efficient Data Loading with Ecto

### Loading Aggregates and Virtual Fields
- Use lateral joins with subqueries to avoid N+1 queries when loading counts and computed fields
- Define virtual fields in schemas for data that isn't stored in the database
- Use `with_stats/2` pattern to efficiently load articles with favorites count and favorited status
- Example implementation:
  ```elixir
  def with_stats(query, user) do
    favorites_count_query = 
      from f in ArticleFavorite,
      where: f.article_id == parent_as(:article).id,
      select: %{count: count(f.article_id)}
    
    from a in query,
      as: :article,
      left_lateral_join: fc in subquery(favorites_count_query),
      on: true,
      select_merge: %{
        favorites_count: coalesce(fc.count, 0)
      }
  end
  ```
- This approach loads all data in a single query instead of N+1 queries

## Infinite Scrolling with LiveView
- Use LiveView's built-in `phx-viewport-bottom` binding - NO custom JavaScript needed
- Implement cursor-based pagination (not offset-based) for better performance
- Track pagination state in socket assigns: `:page`, `:per_page`, `:end_of_feed?`, `:last_article_id`
- Use dynamic padding on container to trigger viewport events: `pb-[calc(200vh)]` when more content available
- Handle "next-page" event to load more content
- Streams automatically append new items without re-rendering existing ones

## Template Patterns
- Use `:if` attribute on elements instead of `<%= if %>` blocks when checking permissions
- `Policies.permit?` handles nil users, so no need for `@current_user &&` checks
- Use pattern matching in templates for cleaner routing logic
- Prefer context-aware navigation links that preserve current feed type

## Query Composition with Joins
- When adding joins to queries that already have policy scopes, be mindful of binding positions
- Use `[a, ...]` in join clauses to handle variable number of existing joins
- Be explicit with bindings in where/order_by clauses when multiple joins exist
- Example: `where([a, _uf, t], t.name == ^tag_name)` where positions matter

## Policies Enhancements
- `Policies.permit?/3` now accepts a list of actions: `permit?([:update, :delete], user, resource)`
- Returns true if ANY action in the list is permitted
- Reduces code duplication in templates when checking multiple permissions

## Helper Module Organization
- Extract common functions to dedicated helper modules (e.g., `DateTimeHelpers`)
- Import helpers in LiveViews that need them to avoid duplication
- Keep helper modules focused on single responsibilities

## Code Management Memories
- never keep stuff for backwards compatibility unless I tell you otherwise
- Always remove duplicate code by extracting to shared modules
- Update all references when changing function signatures or module names