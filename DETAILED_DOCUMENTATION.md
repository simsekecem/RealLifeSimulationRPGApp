# DETAILED_DOCUMENTATION.md

## RealLifeSimulationRPGApp Technical Documentation

This document provides a comprehensive, file-by-file technical documentation for the "RealLifeSimulationRPGApp" Godot project, explaining the purpose, structure, and key functionalities of each script (`.gd`) and scene (`.tscn`) file.

---

### `scripts/globals.gd`

*   **Purpose:** This script serves as a central AutoLoad (singleton) for global game state management, data persistence, and core application logic. It holds crucial data like user information, game cache, and manages scene transitions.
*   **Key Functionality:**
    *   **Data Cache:** `cache: Dictionary` stores various game data, including user details, inventory, progress, and logs (e.g., `gym_log`, `restaurant`).
    *   **Data Persistence:** `_save_to_local_json()` and `_load_from_local_json()` handle saving and loading the `cache` to/from `user://game_data.json` for offline access.
    *   **Online/Offline Synchronization:** `_sync_data()` and `_send_data_to_worker()` manage synchronization with a Cloudflare Worker backend. It uses an `HTTPRequest` to send local data and retrieve server updates.
    *   **Authentication & Session Management:** Stores `auth_token` and handles initial data fetching post-login.
    *   **Scene Management:** `change_scene_with_loading()` and `_async_load_scene()` facilitate asynchronous scene loading with an intermediary `LoadingScreen`. It ensures data synchronization (`_sync_data`) before loading the target scene.
    *   **Door Interaction Logic:** `handle_door_interaction()` manages scene transitions initiated by interacting with doors, handling player positioning and locked/unlocked states.
    *   **Global Accessors:** Provides convenient methods like `get_gym_level()` and `add_experience()`.
    *   **AI Chatbot Configuration:** Stores URLs and names for various AI chatbots (e.g., `AI_CHATBOT_URL`, `bot_name`).
*   **Notes:** As an AutoLoad, its `_ready()` function is executed once at the start of the game, making it ideal for initialization tasks like loading cached data and setting up connections. The `_notification()` method handles `NOTIFICATION_WM_CLOSE_REQUEST` to ensure data is saved when the application closes.

### `scripts/AuthBase.gd`

*   **Purpose:** This script acts as a base class or utility for handling authentication-related API calls to a Cloudflare Worker backend. It abstracts away the details of making HTTP requests for login, signup, password reset, and token verification.
*   **Key Functionality:**
    *   **`authenticate_request(url_path: String, body: Dictionary, method: HTTPClient.Method)`:** A generic method to send authenticated requests to the Cloudflare Worker. It includes the `Authorization` header with `Globals.auth_token` if available.
    *   **`_on_request_completed(_result, response_code, headers, body)`:** A handler for HTTP request completion. It processes the response, extracts data, and emits signals (`auth_success`, `auth_failed`, `worker_error`) based on the outcome.
    *   **Error Handling:** Differentiates between HTTP errors and custom worker errors embedded in the response body.
*   **Notes:** This script is designed to be used by other authentication scripts (like `Login.gd`, `Signup.gd`, `ResetPassword.gd`) to standardize communication with the authentication backend.

### `scripts/AuthScreen.gd`

*   **Purpose:** This script likely served as a primary authentication screen but its `_ready()` function, which contains Supabase login logic, is commented out. This suggests it might be deprecated, undergoing refactoring, or a fallback that is not currently active in the main authentication flow.
*   **Key Functionality (if active):** Would handle user login using Supabase and update `Globals.auth_token` upon successful authentication.
*   **Notes:** Its redundancy with other auth scripts (e.g., `Login.gd`, `Signup.gd` which use `AuthBase.gd` for a Cloudflare Worker backend) indicates a possible architectural shift or dual backend approach. For current game flow, it appears inactive.

### `scripts/forgot_password_label.gd`

*   **Purpose:** This script makes a `Label` node clickable and triggers the display of the `authscreen_forgotps.tscn` popup when clicked.
*   **Key Functionality:**
    *   **`_gui_input(event)`:** Detects `InputEventMouseButton` (left click) on the label.
    *   **`_on_forgot_password_label_pressed()`:** Hides the parent node (presumably the login screen) and instantiates/shows the `ResetPassword` scene (`authscreen_forgotps.tscn`).
*   **Notes:** Provides a simple navigation link for password recovery within the authentication flow.

### `scripts/GymScreen.gd`

*   **Purpose:** This script manages the `GymScreen` interface, allowing the player to perform various exercises, track their progress, and gain experience points.
*   **Key Functionality:**
    *   **Exercise Management:** Defines different exercise types (`Bench Press`, `Deadlift`, `Squat`, `Cardio`).
    *   **UI Updates:** Dynamically updates labels to display current gym level, experience, next level XP, and exercise progress.
    *   **Exercise Logic:** `perform_exercise()` simulates an exercise session, adding logs to `Globals.cache.gym_log` and granting experience.
    *   **AI Coach Integration:** When an exercise is completed, it presents a button to open an AI Coach chat (`chat_popup.tscn`) to get feedback based on gym logs.
    *   **Synchronization:** Uses `Globals.send_data_to_worker()` to sync updated gym data with the backend.
*   **Notes:** `_set_gym_ui()` centralizes UI updates. `get_gym_xp_for_level()` calculates XP required for levels. This screen provides a core "activity" loop for player progression in the game.

### `scripts/Interactable.gd`

*   **Purpose:** This script serves as a generic base class for interactive objects in the game world (e.g., wardrobe, beds, calendar, NPCs). It defines common behavior for detecting player proximity and triggering interactions after a short delay.
*   **Key Functionality:**
    *   **Player Detection:** Uses `Area2D` signals (`body_entered`, `body_exited`) to detect when a player enters or leaves its area.
    *   **Timed Interaction:** A `Timer` (`wait_timer`) is used to ensure the player remains in the interaction zone for a `wait_time` duration before interaction logic is triggered. This prevents accidental quick interactions.
    *   **Visual Feedback:** Changes the color (`modulate`) of a child `Panel` (if present) to provide visual feedback when the player is ready to interact.
    *   **`interact()` (Virtual Method):** A placeholder method intended to be overridden by specific interactive objects to define their unique interaction behavior.
*   **Notes:** `_on_body_entered()` and `_on_body_exited()` manage the `wait_timer`. `_on_wait_timer_timeout()` calls the virtual `interact()` method. This script is a fundamental building block for making game elements responsive to the player.

### `scripts/ItemCard.gd`

*   **Purpose:** This script manages the display and interaction logic for a single item card within a list (e.g., in the wardrobe's item list popup). It handles displaying item information, loading remote images, and emitting signals for user actions like selection, deletion, or editing.
*   **Key Functionality:**
    *   **Data Display:** Sets the `NameLabel`, `ConfidenceLabel`, and `TextureRect` (for item image) based on provided item data.
    *   **Remote Image Loading:** Uses `HTTPRequest` to asynchronously load item images from a URL (`image_url`). It displays a loading indicator and handles errors.
    *   **User Actions:** Emits signals (`selected`, `deleted`, `edit_requested`) when corresponding buttons are pressed.
    *   **Customization:** Can be configured to hide the "Edit" and "Delete" buttons, making it suitable for different display contexts.
*   **Notes:** The `_on_http_request_completed()` method processes the downloaded image. `_on_edit_button_pressed()` and `_on_delete_button_pressed()` emit signals, allowing parent nodes to handle the actual logic for editing/deleting items. This script is essential for dynamic item lists.

### `scripts/LibraryScreen.gd`

*   **Purpose:** This script manages the `LibraryScreen` interface, offering dual functionality: book tracking (reading, finished, wishlist) and study hour logging.
*   **Key Functionality:**
    *   **Tab Management:** Uses a `TabContainer` (`TabContainerBooks`) to switch between "Book Tracker" and "Study Tracker" interfaces.
    *   **Book Tracking:**
        *   `add_book()`: Adds new books to `Globals.cache.library.books`.
        *   `_update_book_list()`: Dynamically populates book lists (`ReadingList`, `FinishedList`, `Wishlist`) using a `book_row_prefab`.
        *   `_on_book_row_status_changed()`: Updates book status (reading, finished, wishlist) in the cache.
    *   **Study Tracking:**
        *   `_update_study_tracker_ui()`: Displays total study hours, daily goal, and updates a progress bar.
        *   `add_study_hours()`: Adds logged study hours to `Globals.cache.library.study_log`.
        *   `_get_daily_study_hours()`: Calculates study hours for the current day.
    *   **Data Persistence:** All changes are immediately saved to `Globals.cache.library` and marked as dirty for synchronization.
*   **Notes:** The script effectively manages complex data structures within `Globals.cache` for both book and study tracking. It also demonstrates good UI management by dynamically creating and updating list items (`book_row_prefab`).

### `scripts/LoadingScreen.gd`

*   **Purpose:** This script manages the asynchronous loading of game scenes, displaying a progress bar and ensuring necessary data synchronization occurs during transitions. It works in conjunction with `Globals.change_scene_with_loading()`.
*   **Key Functionality:**
    *   **Scene Loading:** `load_new_scene(path: String)` is the main entry point, initiating an asynchronous load (`ResourceLoader.load_threaded_request()`).
    *   **Progress Tracking:** Monitors the loading progress and updates the `ProgressBar` (`_update_progress_bar()`).
    *   **Data Synchronization:** Triggers `Globals.sync_data()` during loading to ensure data is up-to-date before the new scene is displayed.
    *   **Completion:** Once loading is complete and data is synced, it loads the requested scene into the `MainGame` scene.
*   **Notes:** This script uses Godot's threaded loading capabilities (`ResourceLoader`) to prevent the game from freezing during scene transitions, providing a smoother user experience. The `_process()` function is critical for continuous progress bar updates.

### `scripts/Login.gd`

*   **Purpose:** This script handles the user login functionality, interacting with the authentication backend via `AuthBase.gd`.
*   **Key Functionality:**
    *   **User Input:** Retrieves `username_text` and `password_text` from `LineEdit` nodes.
    *   **Login Request:** Calls `auth_base.authenticate_request()` with login credentials to the Cloudflare Worker.
    *   **Response Handling:** Connects to `auth_base.auth_success` and `auth_base.auth_failed` signals.
        *   On success, it updates `Globals.auth_token`, `Globals.user_id`, and calls `Globals.sync_data()` to load user-specific data. It then transitions to the `MainGame` scene.
        *   On failure, it displays an error message.
*   **Notes:** This script demonstrates the use of `AuthBase.gd` for clean separation of concerns regarding authentication logic. It integrates with `Globals` for global state updates and scene transitions.

### `scripts/MainGame.gd`

*   **Purpose:** This script serves as the central manager for the entire game, orchestrating scene changes, player loading, camera control, and managing the overall game flow. It's the primary script for the `MainGame.tscn` scene.
*   **Key Functionality:**
    *   **Initialization:** In `_ready()`, it sets up global properties (`self_ref`, `game_state`, `camera`), loads the initial `town.tscn` scene, and places the player.
    *   **Scene Management:** `load_scene_into_container()` is a core method for dynamically loading sub-scenes (like `town.tscn`, `house.tscn`, `market.tscn`, `resturant.tscn`, `GymScreen.tscn`, `LibraryScreen.tscn`, `Wardrobe.tscn`) into specific container nodes (`TownContainer`, `HomeContainer`) of the `MainGame` scene.
    *   **Player Spawning & Positioning:** Places the player instance (`player_prefab`) into the current scene and handles its initial position.
    *   **Camera Control:** Manages the game camera, potentially switching between different camera setups depending on the current scene.
    *   **Global Access:** Stores a reference to itself (`Globals.main_game_ref`) for easy access from other scripts.
    *   **Door Interaction:** Responds to the `door_interacted` signal from `Globals` to facilitate scene transitions when a player uses a door.
*   **Notes:** This is a highly critical script, centralizing many aspects of the game's core loop. The use of container nodes (`TownContainer`, `HomeContainer`) enables a modular and flexible scene architecture. It relies heavily on `Globals` for shared state and functionality.

### `scripts/market.gd`

*   **Purpose:** This script manages the `Market` scene, providing an interface for players to browse and purchase items categorized into "Clothes", "Food", and "Furniture". It also handles saving changes to the player's inventory.
*   **Key Functionality:**
    *   **Tab-Based Categories:** Uses a `TabContainer` to switch between different item categories.
    *   **Dynamic Item Lists:** Each category tab likely contains a `panel.tscn` (ItemPanel) which dynamically populates with `shopping_row.tscn` (ShoppingRow) instances based on item data from `Globals.market_items`.
    *   **Item Filtering:** Filters items by availability (`is_available`).
    *   **Purchase Logic (implied):** While not explicit in the provided snippets, `shopping_row.gd` (which is used here) would handle individual item purchase logic and update the player's inventory in `Globals.cache.inventory`.
    *   **Data Saving:** `_save_market_state()` saves the current state of market items to `Globals.cache.market` when changing tabs or exiting the screen.
*   **Notes:** This script works in conjunction with `panel.gd` and `shopping_row.gd` to create a functional and organized market interface. The use of `Globals.market_items` and `Globals.cache.market` implies a global, persistent market state.

### `scripts/panel.gd`

*   **Purpose:** This script manages a reusable `Panel` component, typically used within lists or grids to display and manage a collection of items (e.g., categories in the market, items in the wardrobe). It handles populating the panel with children, updating their visibility, and clearing existing items.
*   **Key Functionality:**
    *   **Dynamic Population:** `populate(items: Array, prefab_scene: PackedScene)` instantiates `prefab_scene` for each item in the `items` array and adds it as a child.
    *   **Visibility Control:** `_set_item_visibility()` and `set_all_visible()` control the visibility of child nodes based on a given filter.
    *   **Clearing Children:** `clear_children()` removes all child nodes.
*   **Notes:** This script serves as a foundational component for building dynamic item lists and grids. Its generic nature allows it to be used with various `prefab_scene` types, making it highly reusable.

### `scripts/Player.gd`

*   **Purpose:** This script defines the player character's behavior, including movement, animation, and visual customization. It is a core component of the game's interactive experience.
*   **Key Functionality:**
    *   **Movement:** Handles player movement based on keyboard input (`Input.get_vector()`) and potentially a virtual joystick. Uses `move_and_slide()` for physics-based movement.
    *   **Animation:** Manages player animations (`AnimatedSprite2D`) based on movement direction (up, down, left, right).
    *   **Visual Customization:** `set_player_visuals()` dynamically loads `SpriteFrames` resources based on `Globals.cache.user.character_id`, allowing the player's appearance to change.
    *   **Optimization:** Prevents redundant `SpriteFrames` loading by checking `last_character_id`.
    *   **Global Access:** Sets `Globals.player_ref = self` for easy access from other scripts.
*   **Notes:** The `_physics_process()` function is the heart of player movement. The `set_player_visuals()` function is critical for supporting character customization, a common RPG feature.

### `scripts/ResetPassword.gd`

*   **Purpose:** This script handles the password reset functionality, allowing users to request a password reset email and then submit a new password. It interacts with the authentication backend via `AuthBase.gd`.
*   **Key Functionality:**
    *   **Email Request:** `_on_email_reset_button_pressed()` sends a request with the user's email to initiate the password reset process.
    *   **Password Submission:** `_on_reset_password_button_pressed()` sends a request with the email, new password, and verification code.
    *   **Response Handling:** Connects to `auth_base.auth_success` and `auth_base.auth_failed` signals.
        *   On successful email request, it changes the UI to show the password input fields.
        *   On successful password reset, it returns to the login screen.
        *   On failure, it displays an error message.
*   **Notes:** Similar to `Login.gd` and `Signup.gd`, this script utilizes `AuthBase.gd` for backend communication, ensuring consistency in authentication requests.

### `scripts/resturant.gd`

*   **Purpose:** This script manages the `Restaurant` screen, allowing players to log their daily meals and add notes. It emphasizes date handling and real-time data saving.
*   **Key Functionality:**
    *   **Meal Logging:** Players can input meal details and save them to `Globals.cache.restaurant`.
    *   **Date Selection:** Uses a calendar UI (`DateEdit` and `CalendarPopup`) to allow players to select specific dates for logging meals.
    *   **Dynamic UI Update:** `_update_ui_for_date()` refreshes the displayed meal logs and notes based on the selected date.
    *   **Data Deduplication:** Ensures that only one log entry exists per day by checking `_current_date_exists_in_logs()`.
    *   **AI Dietitian Integration:** Provides a button to open the `chat_popup_r.tscn` (AI Dietitian Chat) to get dietary advice.
    *   **Data Persistence:** All meal logs are saved to `Globals.cache.restaurant` and marked as dirty for synchronization.
*   **Notes:** This script extensively uses Godot's date and time functions to manage meal logs chronologically. The AI integration adds a layer of personalized feedback to the player's dietary habits.

### `scripts/shopping_row.gd`

*   **Purpose:** This script manages the display and interaction logic for a single item row within a shopping list (e.g., in the market). It displays item details, handles quantity adjustments, and calculates prices.
*   **Key Functionality:**
    *   **Data Display:** Sets the `NameLabel`, `PriceLabel`, and `QuantityLabel` based on provided item data.
    *   **Quantity Adjustment:** Allows the player to increase or decrease the quantity of an item using buttons, ensuring quantities don't go below zero.
    *   **Price Calculation:** Dynamically updates the `TotalLabel` based on quantity and item price.
    *   **Availability:** Greys out (`modulate`) the row if the item is not available.
    *   **Signals:** Emits `changed` signal whenever the quantity is altered, allowing the parent (e.g., `market.gd` or `panel.gd`) to react.
*   **Notes:** This script is a reusable component for interactive item lists. It encapsulates the logic for managing a single item's purchase details, which is then aggregated by its parent.

### `scripts/Signup.gd`

*   **Purpose:** This script handles the user registration (signup) functionality, interacting with the authentication backend via `AuthBase.gd`.
*   **Key Functionality:**
    *   **User Input:** Retrieves `username_text`, `password_text`, `email_text` from `LineEdit` nodes.
    *   **Registration Request:** Calls `auth_base.authenticate_request()` with registration details to the Cloudflare Worker.
    *   **Response Handling:** Connects to `auth_base.auth_success` and `auth_base.auth_failed` signals.
        *   On success, it updates `Globals.auth_token`, `Globals.user_id`, and calls `Globals.sync_data()`. It then transitions to the `MainGame` scene.
        *   On failure, it displays an error message.
*   **Notes:** This script completes the authentication suite, using `AuthBase.gd` and integrating with `Globals` for global state and scene transitions.

### `scripts/town.gd`

*   **Purpose:** This script manages the `Town` scene, which is the main exterior environment of the game. Its primary responsibility is to ensure that player data is synchronized with the backend when the town scene is loaded.
*   **Key Functionality:**
    *   **Data Synchronization:** In `_ready()`, it calls `Globals.sync_data()` to fetch the latest player data from the Cloudflare Worker when the town scene becomes active.
*   **Notes:** This script is minimal, focusing solely on data synchronization upon entry to the town. More complex town-specific logic (NPC interactions, quests, weather) would typically be managed by individual nodes within the `town.tscn` scene or other specialized scripts.

### `scripts/Wardrobe.gd`

*   **Purpose:** This script manages the `Wardrobe` interface, allowing players to manage their clothing inventory, upload new clothes via image, classify them using AI, generate outfits, and view categorized clothing items.
*   **Key Functionality:**
    *   **Clothing Inventory Management:** Displays categorized lists of clothes, allowing selection, deletion, and editing via `WardrobeItemListPopup.tscn`.
    *   **Image Upload:** Handles image uploads (`_on_file_dialog_file_selected()`) to Supabase Storage.
    *   **AI Clothing Classification:** Sends uploaded images to a Cloudflare Worker for AI classification (`_send_image_to_ai_classifier()`).
    *   **AI Outfit Generation:** Sends current clothes and player profile to a Cloudflare Worker for AI outfit generation (`_send_to_ai_outfit_generator()`).
    *   **Outfit Display:** Shows AI-generated outfit results via `OutfitResultPopup.tscn`.
    *   **Background Image Management:** Handles loading and caching of background images from URLs.
    *   **Synchronization:** Updates `Globals.cache.wardrobe` and synchronizes with the backend.
*   **Notes:** This script is complex, integrating Supabase Storage, two different AI services (classification and generation), and dynamic UI updates for clothing items. It's a central hub for character customization.

### `scripts/WardrobeItemListPopup.gd`

*   **Purpose:** This script manages a popup window that displays categorized lists of clothing items (e.g., "T-shirts", "Pants", "Shoes"). It allows players to select, delete, or edit individual items.
*   **Key Functionality:**
    *   **Dynamic Item Display:** Populates various `panel.tscn` instances (e.g., `PanelTShirt`, `PanelPants`) with `ItemCard.tscn` prefabs based on the selected category.
    *   **Filtering:** Filters displayed items by category.
    *   **Item Actions:** Responds to signals from `ItemCard.gd` (`selected`, `deleted`, `edit_requested`) to update the wardrobe data in `Globals.cache.wardrobe` and potentially trigger further UI updates or backend calls.
    *   **Customization:** Can be configured to hide edit/delete buttons for certain contexts.
*   **Notes:** This script is essential for detailed management of the player's clothing inventory, working in conjunction with `panel.gd` and `ItemCard.gd`.

### `npc_interactable.gd`

*   **Purpose:** This script defines the behavior for an interactive NPC. It handles player detection, displays a customizable dialogue bubble, makes the NPC face the player, and has a placeholder for specific interaction logic based on the `interact_type`. This script serves as the base for all `npc_interactable` instances (e.g., `npc_interactable_1.gd`, `npc_interactable_2.gd`, `npc_interactable_3.gd` are redundant copies of this script).
*   **Extends:** `Area2D`.
*   **Key Functionality:**
    *   **Configurable Properties:** `@export_enum` `interact_type` (Gym, Market, Restaurant, Library) and `@export_multiline` `dialog_text` allow customization directly in the editor. `@export` `wait_time` controls interaction delay.
    *   **Player Detection & Interaction Trigger:** Uses `Area2D` signals (`body_entered`, `body_exited`) and a `Timer` to trigger dialogue after the player remains in the interaction zone for `wait_time`.
    *   **Visual Feedback:** `flip_towards_player()` makes the NPC sprite face the player. `show_dialogue()` makes the `dialog_bubble` visible and sets the `quest_label.text`.
    *   **Extensible Interaction Logic:** `interaction_logic()` uses a `match` statement based on `interact_type` as a placeholder for implementing unique behaviors for each NPC type.
*   **Notes:** This script is designed for reusability. The visual appearance of the NPC (sprite, scale, region) is handled in the `.tscn` file, while dialogue content and interaction type are configured via exported variables, allowing for diverse NPCs with a single underlying script.

---

### `chat_message.gd`

*   **Purpose:** This script dynamically sets the content and visual alignment of a generic chat message bubble, using a pinkish color for user messages and white for AI messages.
*   **Extends:** `HBoxContainer`.
*   **Key Functionality:**
    *   **`setup(content: String, is_user: bool)`:** Sets `MessageLabel.text` to `content`.
    *   **Dynamic Alignment:** Sets `layout_direction` of the `HBoxContainer` to `RTL` (right-to-left) for user messages and `LTR` (left-to-right) for AI messages.
    *   **Color Modulation:** Modulates the color of the `BubblePanel` to distinguish between user (pinkish) and AI (white) messages.
*   **Notes:** This script is used by the generic `chat_popup.tscn` to display chat messages. Its design handles both left and right alignment, making it a versatile prefab.

### `chat_message_l.gd`

*   **Purpose:** This script dynamically sets the content and visual alignment of a chat message bubble, specifically for messages originating from the "left" side (e.g., an NPC or another player). It uses a light purple/blue for user messages and a darker purple for AI messages.
*   **Extends:** `HBoxContainer`.
*   **Key Functionality:**
    *   **`setup(content: String, is_user: bool)`:** Sets `MessageLabel.text` to `content`.
    *   **Dynamic Alignment:** Sets `layout_direction` of the `HBoxContainer` to `RTL` (right-to-left) for user messages and `LTR` (left-to-right) for AI messages.
    *   **Color Modulation:** Modulates the color of the `BubblePanel` to distinguish between user (light purple/blue) and AI (darker purple) messages.
*   **Notes:** Despite the `_l` in its name, this script's `is_user` logic makes it handle both left and right alignment. It is likely used by `chat_popup_l.tscn` and has a distinct color scheme compared to the generic `chat_message.gd`.

### `chat_popup.gd`

*   **Purpose:** This script implements the core logic for a generic AI chatbot popup, specifically tailored for an "AI Coach" interaction, utilizing the player's `gym_log` data as context.
*   **Extends:** `CanvasLayer`.
*   **Key Functionality:**
    *   **Message Management:** `add_message_to_chat()` instantiates `chat_message.tscn` prefabs and adds them to the `message_list`.
    *   **AI Communication:** `_send_to_ai_coach()` sends user messages along with `gym_logs` (context) to a Cloudflare Worker endpoint (`/api/ai_chat`).
    *   **Context Management:** Limits `gym_logs` to the latest 50 entries to manage AI token limits.
    *   **UI Feedback:** Manages `is_waiting_for_response` flag, updates input field placeholder text, and disables input while awaiting AI response.
    *   **Error Handling:** Displays error messages for failed API requests or malformed AI responses.
*   **Notes:** This script leverages player data to enable contextual AI interactions. It is designed to work with the generic `chat_message.tscn` prefab.

### `chat_popup_l.gd`

*   **Purpose:** This script manages the core functionality of a chat popup, including displaying messages, handling user input, sending messages to a backend AI, and processing AI responses. It is structurally similar to `chat_popup.gd` but likely uses `chat_message_l.tscn` for its messages.
*   **Extends:** `CanvasLayer`.
*   **Key Functionality:**
    *   (Details are assumed to be similar to `chat_popup.gd` as the provided content for `chat_popup_l.gd` was empty `extends CanvasLayer`). Based on the scene `chat_popup_l.tscn`, it would manage a message list, input field, send button, and `HTTPRequest` for AI communication.
*   **Notes:** Given its name, it likely serves as a "left-aligned" general purpose chat popup, possibly for interactions where the NPC/AI is the primary "speaker" or has a default left alignment.

### `chat_popup_r.gd`

*   **Purpose:** This script powers a specialized "right-sided" chat popup for interaction with an AI Dietitian. It handles sending user queries, provides context from the player's meal logs (`restaurant` data), processes AI responses, and displays the conversation.
*   **Extends:** `CanvasLayer`.
*   **Key Functionality:**
    *   **Message Management:** `add_message_to_chat()` instantiates `chat_message_r.tscn` prefabs and adds them to the `message_list`.
    *   **AI Communication:** `_send_to_ai_dietitian()` sends user messages along with `diet_logs` (context from `Globals.cache.restaurant`) to a specific Cloudflare Worker endpoint (`/api/ai_diet`).
    *   **Context Management:** Limits `diet_logs` to the latest 40 entries to manage AI token limits.
    *   **UI Feedback:** Manages `is_waiting_for_response` flag, updates input field placeholder text, and disables input while awaiting AI response.
    *   **Error Handling:** Displays error messages for failed API requests or malformed AI responses.
*   **Notes:** This script demonstrates a targeted AI integration, using player data to enable personalized and relevant advice from an AI Dietitian. It works with the `chat_message_r.tscn` prefab.

---

### `scenes/Autoloads/music_controller.tscn`

*   **Purpose:** This scene defines a global `MusicController` node, intended as an AutoLoad (singleton) to manage background music playback throughout the game.
*   **Root Node:** `Node2D`.
*   **Key Components:**
    *   **`MusicController` (Node2D):** Root node, with `music_controller.gd` attached.
    *   **`AudioStreamPlayer`:** Child node, configured to play `Blithe part B.ogg` on the "Music" audio bus.
*   **Notes:** As an AutoLoad, it ensures continuous background music across scene changes and provides a centralized point for music control.

### `scenes/chat_message_l.tscn`

*   **Purpose:** This scene defines the visual and structural layout of a single chat message bubble, specifically designed for messages originating from the "left" side.
*   **Root Node:** `HBoxContainer`.
*   **Key Components:**
    *   **`ChatMessage_l` (HBoxContainer):** Root node, with `chat_message_l.gd` attached.
    *   **`BubblePanel` (PanelContainer):** The visual bubble, styled with `StyleBoxFlat` (light purple/blue, rounded corners).
    *   **`MessageLabel` (Label):** Displays the message text, using `PressStart2P-Regular.ttf` and `autowrap_mode = 3` for multi-line text.
*   **Notes:** Uses `LibraryScreen.tres` as a theme, which might be a general UI theme or indicate shared styling with the library screen.

### `scenes/chat_popup_l.tscn`

*   **Purpose:** This scene defines a full-screen, modal chat popup interface, visually aligned for "left-sided" chat.
*   **Root Node:** `CanvasLayer`.
*   **Key Components:**
    *   **`ChatPopup_L` (CanvasLayer):** Root node, with `chat_popup_l.gd` attached.
    *   **`BackgroundDimmer` (ColorRect):** Semi-transparent background (light purple hue).
    *   **`MainWindow` (NinePatchRect):** Main chat window.
    *   **`MessageList` (VBoxContainer within `ScrollContainer`):** Container for chat message bubbles.
    *   **`CloseButton` (Button):** "X" button.
    *   **`TitleLabel` (Label):** Displays "AI CHATBOT".
    *   **`InputField` (LineEdit):** User input.
    *   **`SendButton` (Button):** Sends message.
    *   **`HTTPRequest`:** For backend AI communication.
*   **Notes:** Uses `LibraryScreen.tres` theme. The `_L` suffix suggests a left-aligned visual style.

### `scenes/chat_popup_r.tscn`

*   **Purpose:** This scene defines a full-screen, modal chat popup interface with a distinct visual theme (pink/greenish colors), likely for a specific context like the AI Dietitian chat.
*   **Root Node:** `CanvasLayer`.
*   **Key Components:**
    *   **`ChatPopup_R` (CanvasLayer):** Root node, with `chat_popup_r.gd` attached.
    *   **`BackgroundDimmer` (ColorRect):** Semi-transparent background (pinkish hue).
    *   **`MainWindow` (NinePatchRect):** Main chat window.
    *   **`MessageList` (VBoxContainer within `ScrollContainer`):** Container for chat message bubbles.
    *   **`CloseButton` (Button):** "X" button.
    *   **`TitleLabel` (Label):** Displays "AI CHATBOT".
    *   **`InputField` (LineEdit):** User input.
    *   **`SendButton` (Button):** Sends message.
    *   **`HTTPRequest`:** For backend AI communication.
*   **Notes:** Uses `resturant.tres` theme. The `_R` suffix suggests a right-aligned or thematically distinct chat.

### `scenes/chat_popup.tscn`

*   **Purpose:** This scene defines a generic full-screen, modal chat popup interface, used for the "AI Coach" chat, structurally similar to `chat_popup_l.tscn` but potentially more flexible with message alignment.
*   **Root Node:** `CanvasLayer`.
*   **Key Components:**
    *   **`ChatPopup` (CanvasLayer):** Root node, with `chat_popup.gd` attached.
    *   **`BackgroundDimmer` (ColorRect):** Semi-transparent background (light purple hue).
    *   **`MainWindow` (NinePatchRect):** Main chat window.
    *   **`MessageList` (VBoxContainer within `ScrollContainer`):** Container for chat message bubbles.
    *   **`CloseButton` (Button):** "X" button.
    *   **`TitleLabel` (Label):** Displays "CHATBOT".
    *   **`InputField` (LineEdit):** User input.
    *   **`SendButton` (Button):** Sends message.
    *   **`HTTPRequest`:** For backend AI communication.
*   **Notes:** Uses `LibraryScreen.tres` theme. Intended for generic AI conversations that may not require specific left/right styling distinctions.

### `scenes/cow.tscn`

*   **Purpose:** This scene defines an interactive `Cow` character for the game world.
*   **Root Node:** `Area2D`.
*   **Key Components:**
    *   **`Cow` (Area2D):** Root node, with `cow.gd` attached.
    *   **`CollisionShape2D`:** Defines the interaction area (circular).
    *   **`Sprite2D`:** Visual representation of the cow (`cow.png`).
    *   **`Timer`:** For timed interactions or delays.
    *   **`DialogBubble` (Control):** A hidden speech bubble for displaying text (e.g., "MOOO!"), styled with `StyleBoxFlat`.
*   **Notes:** Implements basic NPC interaction: player proximity, timed dialogue, and facing the player.

### `scenes/duck.tscn`

*   **Purpose:** This scene defines an animated `Duck` character, likely an ambient element in the game world.
*   **Root Node:** `CharacterBody2D`.
*   **Key Components:**
    *   **`Duck` (CharacterBody2D):** Root node, with `duck.gd` attached.
    *   **`CollisionShape2D`:** A disabled circular collision shape, suggesting it's primarily a visual element unless activated by script.
    *   **`AnimatedSprite2D`:** Displays `swim_right` animation from `spr_deco_duck_01_strip4.png`.
*   **Notes:** Implements simple patrol movement between two points and sprite flipping based on direction.

### `scenes/GymScreen.tres`

*   **Purpose:** A `Theme` resource providing consistent visual styling for the `GymScreen` and related UI elements.
*   **Resource Type:** `Theme`.
*   **Key Styles:**
    *   **Font:** `PressStart2P-Regular.ttf` for most text.
    *   **Color Palette:** Dominated by pink, purple, and brown tones.
    *   **Control Styling:** Extensive `StyleBoxFlat` definitions for `Button` (normal, hover, pressed), `CheckBox` (checked, unchecked icons, hover styles), `HScrollBar`/`VScrollBar` (grabber styles), `LineEdit`, `PopupMenu`, `SpinBox`, and `TabContainer`. Rounded corners (radius 7 or 15) are a common feature.
*   **Notes:** Creates a distinct aesthetic, often retro or playful, with detailed customization across many UI elements.

### `scenes/house.tscn`

*   **Purpose:** Defines the player's indoor environment, an interactive house.
*   **Root Node:** `Node2D`.
*   **Key Components:**
    *   **Multiple `TileMapLayer`s:** Extensive use of `TileMap`s for floors, walls, and details, utilizing various interior tilesets (`Interior.png`, `house_details.png`, etc.).
    *   **`Player` instance:** The player character.
    *   **`Door` instance:** An exit door to other scenes.
    *   **`CalendarZone` (Area2D with `Interactable.gd`):** An interactive zone for a calendar.
    *   **`Wardrobe` (Area2D with `Interactable.gd`):** An interactive zone for the wardrobe, configured with `interact_type = "Wardrobe"`.
*   **Notes:** A highly detailed tile-based environment, serving as a hub for player activities and customization. Uses `y_sort_enabled` on certain layers for depth.

### `scenes/LibraryScreen.tres`

*   **Purpose:** A `Theme` resource primarily customizing the visual appearance of scrollbars (`HScrollBar` and `VScrollBar`).
*   **Resource Type:** `Theme`.
*   **Key Styles:**
    *   **Color Palette:** Shades of purple, blue, and some pink for scrollbar grabbers and tracks.
    *   **Control Styling:** `StyleBoxFlat` definitions for `HScrollBar`/`VScrollBar` grabber (normal, highlight, pressed) and `VScrollBar` normal/scroll styles. Rounded corners (radius 12 or 15) are prominent.
*   **Notes:** This theme is reused in various UI elements like chat popups, suggesting a general application for interactive panels with scrollable content.

### `scenes/MainGame.tscn`

*   **Purpose:** The central scene managing transitions between different game locations and overall game state.
*   **Root Node:** `Node2D`.
*   **Key Components:**
    *   **`MainGame` (Node2D):** Root node, with `MainGame.gd` attached.
    *   **`TownContainer` (Node2D):** Placeholder for dynamically loaded outdoor scenes (e.g., `town.tscn`).
    *   **`HomeContainer` (Node2D):** Placeholder for dynamically loaded indoor scenes (e.g., `house.tscn`).
    *   **`OthersContainer` (CanvasLayer):** For overlaying UI elements or other scenes.
*   **Notes:** Minimalist scene structure, acting as the orchestrator for modular scene loading.

### `scenes/market.tres`

*   **Purpose:** A `Theme` resource providing consistent visual styling for the `Market` scene.
*   **Resource Type:** `Theme`.
*   **Key Styles:**
    *   **Font:** `PressStart2P-Regular.ttf` as default and for buttons.
    *   **Color Palette:** Distinct blue, light blue, and darker blue/gray shades.
    *   **Control Styling:** `StyleBoxFlat` definitions for `Button` (focus, hover, normal, pressed), `CheckBox` (focus, pressed), `HScrollBar`/`VScrollBar` (grabber styles). Prominent rounded corners (radius 15).
*   **Notes:** Creates a clean, somewhat modern yet pixel-art compatible feel for the market interface.

### `scenes/resturant.tres`

*   **Purpose:** A `Theme` resource providing consistent visual styling for the `Restaurant` scene and related UI elements.
*   **Resource Type:** `Theme`.
*   **Key Styles:**
    *   **Font:** `PressStart2P-Regular.ttf` as default and for buttons.
    *   **Color Palette:** Predominantly pink tones, contrasted with greenish font colors for buttons.
    *   **Control Styling:** `StyleBoxFlat` definitions for `Button` (focus, hover, normal, pressed), `HScrollBar`/`VScrollBar` (grabber styles), and `ScrollContainer` (focus, normal). Rounded corners (radius 15) are common.
*   **Notes:** Creates a warm, thematic user experience for the restaurant interface. Reused in `chat_popup_r.tscn`.

### `scenes/town.tscn`

*   **Purpose:** Defines the expansive outdoor "Town" environment, serving as the main hub where the player interacts with NPCs, accesses different locations, and navigates the game world.
*   **Root Node:** `Node2D`.
*   **Key Components (High-Level Summary based on first few hundred lines and knowledge from `scripts/town.gd`):**
    *   **Multiple `TileMapLayer`s:** The scene is heavily composed of multiple `TileMap` layers using various external tilesets (`map1.png`, `map2.png`, `overworld_tileset_grass.png`, `exterior 16x 16.png`, `Houses Sprite Sheet 16x16.png`, `Houses Sprite Sheet 32x32.png`, `Houses Sprite Sheet 24x24.png`). These layers construct the terrain, roads, buildings, and environmental details, including collision shapes for traversable and non-traversable areas.
    *   **`Player` instance:** The player character.
    *   **`Door` instances:** Multiple instances of `Door.tscn` prefab are present, acting as transition points to other scenes (e.g., `house.tscn`, `market.tscn`, `resturant.tscn`, `GymScreen.tscn`, `LibraryScreen.tscn`, `Wardrobe.tscn`). These doors are configured to lead to specific destinations.
    *   **NPC Instances:** Various NPC prefabs are instantiated:
        *   `npc_interactable.tscn`
        *   `npc_interactable_1.tscn`
        *   `npc_interactable_2.tscn`
        *   `npc_interactable_3.tscn`
        *   `random_npc.tscn`
        *   `duck.tscn` (likely ambient element)
        *   `cow.tscn` (likely ambient element)
    *   **`town.gd` script:** Attached to the root node, managing data synchronization upon scene entry.
*   **Notes:** This is the largest scene in the project, featuring a rich, tile-based environment populated with numerous interactive elements. The extensive use of `TileMap`s with detailed `TileSetAtlasSource` definitions for physics layers indicates a carefully crafted world with defined traversable areas and collision boundaries. The presence of many `Door` and NPC instances highlights its role as a central hub for player progression and interaction.

### `scenes/UserInterface/LoadingScreen.tscn`

*   **Purpose:** Defines the visual interface for a loading screen, providing feedback during scene transitions.
*   **Root Node:** `Control`.
*   **Key Components:**
    *   **`LoadingScreen` (Control):** Root node, with `LoadingScreen.gd` attached.
    *   **`NinePatchRect`:** Displays `loading.png` as a scalable background.
    *   **`ProgressBar`:** Visual progress indicator, customized with `StyleBoxFlat` background and `StyleBoxTexture` fill (using `loadingprogressbar.png`). Uses `PressStart2P-Regular.ttf` for its text.
    *   **`Label`:** Displays "Loading..." text.
*   **Notes:** Uses `maintheme.tres` for consistent styling. Designed to provide a smooth user experience during asynchronous scene loading.

---

### `chat_message.gd`

*   **Purpose:** This script dynamically sets the content and visual alignment of a generic chat message bubble, using a pinkish color for user messages and white for AI messages.
*   **Extends:** `HBoxContainer`.
*   **Key Functionality:**
    *   **`setup(content: String, is_user: bool)`:** Sets `MessageLabel.text` to `content`.
    *   **Dynamic Alignment:** Sets `layout_direction` of the `HBoxContainer` to `RTL` (right-to-left) for user messages and `LTR` (left-to-right) for AI messages.
    *   **Color Modulation:** Modulates the color of the `BubblePanel` to distinguish between user (pinkish) and AI (white) messages.
*   **Notes:** This script is used by the generic `chat_popup.tscn` to display chat messages. Its design handles both left and right alignment, making it a versatile prefab.

### `chat_message_l.gd`

*   **Purpose:** This script dynamically sets the content and visual alignment of a chat message bubble, specifically for messages originating from the "left" side (e.g., an NPC or another player). It uses a light purple/blue for user messages and a darker purple for AI messages.
*   **Extends:** `HBoxContainer`.
*   **Key Functionality:**
    *   **`setup(content: String, is_user: bool)`:** Sets `MessageLabel.text` to `content`.
    *   **Dynamic Alignment:** Sets `layout_direction` of the `HBoxContainer` to `RTL` (right-to-left) for user messages and `LTR` (left-to-right) for AI messages.
    *   **Color Modulation:** Modulates the color of the `BubblePanel` to distinguish between user (light purple/blue) and AI (darker purple) messages.
*   **Notes:** Despite the `_l` in its name, this script's `is_user` logic makes it handle both left and right alignment. It is likely used by `chat_popup_l.tscn` and has a distinct color scheme compared to the generic `chat_message.gd`.

### `chat_popup.gd`

*   **Purpose:** This script implements the core logic for a generic AI chatbot popup, specifically tailored for an "AI Coach" interaction, utilizing the player's `gym_log` data as context.
*   **Extends:** `CanvasLayer`.
*   **Key Functionality:**
    *   **Message Management:** `add_message_to_chat()` instantiates `chat_message.tscn` prefabs and adds them to the `message_list`.
    *   **AI Communication:** `_send_to_ai_coach()` sends user messages along with `gym_logs` (context) to a Cloudflare Worker endpoint (`/api/ai_chat`).
    *   **Context Management:** Limits `gym_logs` to the latest 50 entries to manage AI token limits.
    *   **UI Feedback:** Manages `is_waiting_for_response` flag, updates input field placeholder text, and disables input while awaiting AI response.
    *   **Error Handling:** Displays error messages for failed API requests or malformed AI responses.
*   **Notes:** This script leverages player data to enable contextual AI interactions. It is designed to work with the generic `chat_message.tscn` prefab.

### `chat_popup_l.gd`

*   **Purpose:** This script manages the core functionality of a chat popup, including displaying messages, handling user input, sending messages to a backend AI, and processing AI responses. It is structurally similar to `chat_popup.gd` but likely uses `chat_message_l.tscn` for its messages.
*   **Extends:** `CanvasLayer`.
*   **Key Functionality:**
    *   (Details are assumed to be similar to `chat_popup.gd` as the provided content for `chat_popup_l.gd` was empty `extends CanvasLayer`). Based on the scene `chat_popup_l.tscn`, it would manage a message list, input field, send button, and `HTTPRequest` for AI communication.
*   **Notes:** Given its name, it likely serves as a "left-aligned" general purpose chat popup, possibly for interactions where the NPC/AI is the primary "speaker" or has a default left alignment.

### `chat_popup_r.gd`

*   **Purpose:** This script powers a specialized "right-sided" chat popup for interaction with an AI Dietitian. It handles sending user queries, provides context from the player's meal logs (`restaurant` data), processes AI responses, and displays the conversation.
*   **Extends:** `CanvasLayer`.
*   **Key Functionality:**
    *   **Message Management:** `add_message_to_chat()` instantiates `chat_message_r.tscn` prefabs and adds them to the `message_list`.
    *   **AI Communication:** `_send_to_ai_dietitian()` sends user messages along with `diet_logs` (context from `Globals.cache.restaurant`) to a specific Cloudflare Worker endpoint (`/api/ai_diet`).
    *   **Context Management:** Limits `diet_logs` to the latest 40 entries to manage AI token limits.
    *   **UI Feedback:** Manages `is_waiting_for_response` flag, updates input field placeholder text, and disables input while awaiting AI response.
    *   **Error Handling:** Displays error messages for failed API requests or malformed AI responses.
*   **Notes:** This script demonstrates a targeted AI integration, using player data to enable personalized and relevant advice from an AI Dietitian. It works with the `chat_message_r.tscn` prefab.

---

### `scenes/Autoloads/music_controller.tscn`

*   **Purpose:** This scene defines a global `MusicController` node, intended as an AutoLoad (singleton) to manage background music playback throughout the game.
*   **Root Node:** `Node2D`.
*   **Key Components:**
    *   **`MusicController` (Node2D):** Root node, with `music_controller.gd` attached.
    *   **`AudioStreamPlayer`:** Child node, configured to play `Blithe part B.ogg` on the "Music" audio bus.
*   **Notes:** As an AutoLoad, it ensures continuous background music across scene changes and provides a centralized point for music control.

### `scenes/chat_message_l.tscn`

*   **Purpose:** This scene defines the visual and structural layout of a single chat message bubble, specifically designed for messages originating from the "left" side.
*   **Root Node:** `HBoxContainer`.
*   **Key Components:**
    *   **`ChatMessage_l` (HBoxContainer):** Root node, with `chat_message_l.gd` attached.
    *   **`BubblePanel` (PanelContainer):** The visual bubble, styled with `StyleBoxFlat` (light purple/blue, rounded corners).
    *   **`MessageLabel` (Label):** Displays the message text, using `PressStart2P-Regular.ttf` and `autowrap_mode = 3` for multi-line text.
*   **Notes:** Uses `LibraryScreen.tres` as a theme, which might be a general UI theme or indicate shared styling with the library screen.

### `scenes/chat_popup_l.tscn`

*   **Purpose:** This scene defines a full-screen, modal chat popup interface, visually aligned for "left-sided" chat.
*   **Root Node:** `CanvasLayer`.
*   **Key Components:**
    *   **`ChatPopup_L` (CanvasLayer):** Root node, with `chat_popup_l.gd` attached.
    *   **`BackgroundDimmer` (ColorRect):** Semi-transparent background (light purple hue).
    *   **`MainWindow` (NinePatchRect):** Main chat window.
    *   **`MessageList` (VBoxContainer within `ScrollContainer`):** Container for chat message bubbles.
    *   **`CloseButton` (Button):** "X" button.
    *   **`TitleLabel` (Label):** Displays "AI CHATBOT".
    *   **`InputField` (LineEdit):** User input.
    *   **`SendButton` (Button):** Sends message.
    *   **`HTTPRequest`:** For backend AI communication.
*   **Notes:** Uses `LibraryScreen.tres` theme. The `_L` suffix suggests a left-aligned visual style.

### `scenes/chat_popup_r.tscn`

*   **Purpose:** This scene defines a full-screen, modal chat popup interface with a distinct visual theme (pink/greenish colors), likely for a specific context like the AI Dietitian chat.
*   **Root Node:** `CanvasLayer`.
*   **Key Components:**
    *   **`ChatPopup_R` (CanvasLayer):** Root node, with `chat_popup_r.gd` attached.
    *   **`BackgroundDimmer` (ColorRect):** Semi-transparent background (pinkish hue).
    *   **`MainWindow` (NinePatchRect):** Main chat window.
    *   **`MessageList` (VBoxContainer within `ScrollContainer`):** Container for chat message bubbles.
    *   **`CloseButton` (Button):** "X" button.
    *   **`TitleLabel` (Label):** Displays "AI CHATBOT".
    *   **`InputField` (LineEdit):** User input.
    *   **`SendButton` (Button):** Sends message.
    *   **`HTTPRequest`:** For backend AI communication.
*   **Notes:** Uses `resturant.tres` theme. The `_R` suffix suggests a right-aligned or thematically distinct chat.

### `scenes/chat_popup.tscn`

*   **Purpose:** This scene defines a generic full-screen, modal chat popup interface, used for the "AI Coach" chat, structurally similar to `chat_popup_l.tscn` but potentially more flexible with message alignment.
*   **Root Node:** `CanvasLayer`.
*   **Key Components:**
    *   **`ChatPopup` (CanvasLayer):** Root node, with `chat_popup.gd` attached.
    *   **`BackgroundDimmer` (ColorRect):** Semi-transparent background (light purple hue).
    *   **`MainWindow` (NinePatchRect):** Main chat window.
    *   **`MessageList` (VBoxContainer within `ScrollContainer`):** Container for chat message bubbles.
    *   **`CloseButton` (Button):** "X" button.
    *   **`TitleLabel` (Label):** Displays "CHATBOT".
    *   **`InputField` (LineEdit):** User input.
    *   **`SendButton` (Button):** Sends message.
    *   **`HTTPRequest`:** For backend AI communication.
*   **Notes:** Uses `LibraryScreen.tres` theme. Intended for generic AI conversations that may not require specific left/right styling distinctions.

### `scenes/cow.tscn`

*   **Purpose:** This scene defines an interactive `Cow` character for the game world.
*   **Root Node:** `Area2D`.
*   **Key Components:**
    *   **`Cow` (Area2D):** Root node, with `cow.gd` attached.
    *   **`CollisionShape2D`:** Defines the interaction area (circular).
    *   **`Sprite2D`:** Visual representation of the cow (`cow.png`).
    *   **`Timer`:** For timed interactions or delays.
    *   **`DialogBubble` (Control):** A hidden speech bubble for displaying text (e.g., "MOOO!"), styled with `StyleBoxFlat`.
*   **Notes:** Implements basic NPC interaction: player proximity, timed dialogue, and facing the player.

### `scenes/duck.tscn`

*   **Purpose:** This scene defines an animated `Duck` character, likely an ambient element in the game world.
*   **Root Node:** `CharacterBody2D`.
*   **Key Components:**
    *   **`Duck` (CharacterBody2D):** Root node, with `duck.gd` attached.
    *   **`CollisionShape2D`:** A disabled circular collision shape, suggesting it's primarily a visual element unless activated by script.
    *   **`AnimatedSprite2D`:** Displays `swim_right` animation from `spr_deco_duck_01_strip4.png`.
*   **Notes:** Implements simple patrol movement between two points and sprite flipping based on direction.

### `scenes/GymScreen.tres`

*   **Purpose:** A `Theme` resource providing consistent visual styling for the `GymScreen` and related UI elements.
*   **Resource Type:** `Theme`.
*   **Key Styles:**
    *   **Font:** `PressStart2P-Regular.ttf` for most text.
    *   **Color Palette:** Dominated by pink, purple, and brown tones.
    *   **Control Styling:** Extensive `StyleBoxFlat` definitions for `Button` (normal, hover, pressed), `CheckBox` (checked, unchecked icons, hover styles), `HScrollBar`/`VScrollBar` (grabber styles), `LineEdit`, `PopupMenu`, `SpinBox`, and `TabContainer`. Rounded corners (radius 7 or 15) are a common feature.
*   **Notes:** Creates a distinct aesthetic, often retro or playful, with detailed customization across many UI elements.

### `scenes/house.tscn`

*   **Purpose:** Defines the player's indoor environment, an interactive house.
*   **Root Node:** `Node2D`.
*   **Key Components:**
    *   **Multiple `TileMapLayer`s:** Extensive use of `TileMap`s for floors, walls, and details, utilizing various interior tilesets (`Interior.png`, `house_details.png`, etc.).
    *   **`Player` instance:** The player character.
    *   **`Door` instance:** An exit door to other scenes.
    *   **`CalendarZone` (Area2D with `Interactable.gd`):** An interactive zone for a calendar.
    *   **`Wardrobe` (Area2D with `Interactable.gd`):** An interactive zone for the wardrobe, configured with `interact_type = "Wardrobe"`.
*   **Notes:** A highly detailed tile-based environment, serving as a hub for player activities and customization. Uses `y_sort_enabled` on certain layers for depth.

### `scenes/LibraryScreen.tres`

*   **Purpose:** A `Theme` resource primarily customizing the visual appearance of scrollbars (`HScrollBar` and `VScrollBar`).
*   **Resource Type:** `Theme`.
*   **Key Styles:**
    *   **Color Palette:** Shades of purple, blue, and some pink for scrollbar grabbers and tracks.
    *   **Control Styling:** `StyleBoxFlat` definitions for `HScrollBar`/`VScrollBar` grabber (normal, highlight, pressed) and `VScrollBar` normal/scroll styles. Rounded corners (radius 12 or 15) are prominent.
*   **Notes:** This theme is reused in various UI elements like chat popups, suggesting a general application for interactive panels with scrollable content.

### `scenes/MainGame.tscn`

*   **Purpose:** The central scene managing transitions between different game locations and overall game state.
*   **Root Node:** `Node2D`.
*   **Key Components:**
    *   **`MainGame` (Node2D):** Root node, with `MainGame.gd` attached.
    *   **`TownContainer` (Node2D):** Placeholder for dynamically loaded outdoor scenes (e.g., `town.tscn`).
    *   **`HomeContainer` (Node2D):** Placeholder for dynamically loaded indoor scenes (e.g., `house.tscn`).
    *   **`OthersContainer` (CanvasLayer):** For overlaying UI elements or other scenes.
*   **Notes:** Minimalist scene structure, acting as the orchestrator for modular scene loading.

### `scenes/market.tres`

*   **Purpose:** A `Theme` resource providing consistent visual styling for the `Market` scene.
*   **Resource Type:** `Theme`.
*   **Key Styles:**
    *   **Font:** `PressStart2P-Regular.ttf` as default and for buttons.
    *   **Color Palette:** Distinct blue, light blue, and darker blue/gray shades.
    *   **Control Styling:** `StyleBoxFlat` definitions for `Button` (focus, hover, normal, pressed), `CheckBox` (focus, pressed), `HScrollBar`/`VScrollBar` (grabber styles). Prominent rounded corners (radius 15).
*   **Notes:** Creates a clean, somewhat modern yet pixel-art compatible feel for the market interface.

### `scenes/resturant.tres`

*   **Purpose:** A `Theme` resource providing consistent visual styling for the `Restaurant` scene and related UI elements.
*   **Resource Type:** `Theme`.
*   **Key Styles:**
    *   **Font:** `PressStart2P-Regular.ttf` as default and for buttons.
    *   **Color Palette:** Predominantly pink tones, contrasted with greenish font colors for buttons.
    *   **Control Styling:** `StyleBoxFlat` definitions for `Button` (focus, hover, normal, pressed), `HScrollBar`/`VScrollBar` (grabber styles), and `ScrollContainer` (focus, normal). Rounded corners (radius 15) are common.
*   **Notes:** Creates a warm, thematic user experience for the restaurant interface. Reused in `chat_popup_r.tscn`.

### `scenes/town.tscn`

*   **Purpose:** Defines the expansive outdoor "Town" environment, serving as the main hub where the player interacts with NPCs, accesses different locations, and navigates the game world.
*   **Root Node:** `Node2D`.
*   **Key Components (High-Level Summary based on first few hundred lines and knowledge from `scripts/town.gd`):**
    *   **Multiple `TileMapLayer`s:** The scene is heavily composed of multiple `TileMap` layers using various external tilesets (`map1.png`, `map2.png`, `overworld_tileset_grass.png`, `exterior 16x 16.png`, `Houses Sprite Sheet 16x16.png`, `Houses Sprite Sheet 32x32.png`, `Houses Sprite Sheet 24x24.png`). These layers construct the terrain, roads, buildings, and environmental details, including collision shapes for traversable and non-traversable areas.
    *   **`Player` instance:** The player character.
    *   **`Door` instances:** Multiple instances of `Door.tscn` prefab are present, acting as transition points to other scenes (e.g., `house.tscn`, `market.tscn`, `resturant.tscn`, `GymScreen.tscn`, `LibraryScreen.tscn`, `Wardrobe.tscn`). These doors are configured to lead to specific destinations.
    *   **NPC Instances:** Various NPC prefabs are instantiated:
        *   `npc_interactable.tscn`
        *   `npc_interactable_1.tscn`
        *   `npc_interactable_2.tscn`
        *   `npc_interactable_3.tscn`
        *   `random_npc.tscn`
        *   `duck.tscn` (likely ambient element)
        *   `cow.tscn` (likely ambient element)
    *   **`town.gd` script:** Attached to the root node, managing data synchronization upon scene entry.
*   **Notes:** This is the largest scene in the project, featuring a rich, tile-based environment populated with numerous interactive elements. The extensive use of `TileMap`s with detailed `TileSetAtlasSource` definitions for physics layers indicates a carefully crafted world with defined traversable areas and collision boundaries. The presence of many `Door` and NPC instances highlights its role as a central hub for player progression and interaction.

### `scenes/UserInterface/LoadingScreen.tscn`

*   **Purpose:** Defines the visual interface for a loading screen, providing feedback during scene transitions.
*   **Root Node:** `Control`.
*   **Key Components:**
    *   **`LoadingScreen` (Control):** Root node, with `LoadingScreen.gd` attached.
    *   **`NinePatchRect`:** Displays `loading.png` as a scalable background.
    *   **`ProgressBar`:** Visual progress indicator, customized with `StyleBoxFlat` background and `StyleBoxTexture` fill (using `loadingprogressbar.png`). Uses `PressStart2P-Regular.ttf` for its text.
    *   **`Label`:** Displays "Loading..." text.
*   **Notes:** Uses `maintheme.tres` for consistent styling. Designed to provide a smooth user experience during asynchronous scene loading.

---

This concludes the comprehensive technical documentation for the "RealLifeSimulationRPGApp" Godot project.

### `npc_interactable.gd`

*   **Purpose:** This script defines the behavior for an interactive NPC. It handles player detection, displays a customizable dialogue bubble, makes the NPC face the player, and has a placeholder for specific interaction logic based on the `interact_type`. This script serves as the base for all `npc_interactable` instances (e.g., `npc_interactable_1.gd`, `npc_interactable_2.gd`, `npc_interactable_3.gd` are redundant copies of this script).
*   **Extends:** `Area2D`.
*   **Key Functionality:**
    *   **Configurable Properties:** `@export_enum` `interact_type` (Gym, Market, Restaurant, Library) and `@export_multiline` `dialog_text` allow customization directly in the editor. `@export` `wait_time` controls interaction delay.
    *   **Player Detection & Interaction Trigger:** Uses `Area2D` signals (`body_entered`, `body_exited`) and a `Timer` to trigger dialogue after the player remains in the interaction zone for `wait_time`.
    *   **Visual Feedback:** `flip_towards_player()` makes the NPC sprite face the player. `show_dialogue()` makes the `dialog_bubble` visible and sets the `quest_label.text`.
    *   **Extensible Interaction Logic:** `interaction_logic()` uses a `match` statement based on `interact_type` as a placeholder for implementing unique behaviors for each NPC type.
*   **Notes:** This script is designed for reusability. The visual appearance of the NPC (sprite, scale, region) is handled in the `.tscn` file, while dialogue content and interaction type are configured via exported variables, allowing for diverse NPCs with a single underlying script.

---
