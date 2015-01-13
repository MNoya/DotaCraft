function dotacraft:StartEventTest()
	ListenToGameEvent("team_info", Dynamic_Wrap(dotacraft, 'On_team_info'), self)
	ListenToGameEvent("team_score", Dynamic_Wrap(dotacraft, 'On_team_score'), self)
	ListenToGameEvent("teamplay_broadcast_audio", Dynamic_Wrap(dotacraft, 'On_teamplay_broadcast_audio'), self)
	ListenToGameEvent("player_team", Dynamic_Wrap(dotacraft, 'On_player_team'), self)
	ListenToGameEvent("player_class", Dynamic_Wrap(dotacraft, 'On_player_class'), self)
	ListenToGameEvent("player_death", Dynamic_Wrap(dotacraft, 'On_player_death '), self)
	ListenToGameEvent("player_hurt", Dynamic_Wrap(dotacraft, 'On_player_hurt '), self)
	ListenToGameEvent("player_chat", Dynamic_Wrap(dotacraft, 'On_player_chat '), self)
	ListenToGameEvent("player_score", Dynamic_Wrap(dotacraft, 'On_player_score'), self)
	ListenToGameEvent("player_spawn", Dynamic_Wrap(dotacraft, 'On_player_spawn'), self)
	ListenToGameEvent("player_shoot", Dynamic_Wrap(dotacraft, 'On_player_shoot'), self)
	ListenToGameEvent("player_use", Dynamic_Wrap(dotacraft, 'On_player_use'), self)
	ListenToGameEvent("player_changename", Dynamic_Wrap(dotacraft, 'On_player_changename'), self)
	ListenToGameEvent("player_hintmessage", Dynamic_Wrap(dotacraft, 'On_player_hintmessage'), self)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(dotacraft, 'On_player_reconnected '), self)
	ListenToGameEvent("game_init", Dynamic_Wrap(dotacraft, 'On_game_init'), self)
	ListenToGameEvent("game_newmap", Dynamic_Wrap(dotacraft, 'On_game_newmap'), self)
	ListenToGameEvent("game_start", Dynamic_Wrap(dotacraft, 'On_game_start'), self)
	ListenToGameEvent("game_end", Dynamic_Wrap(dotacraft, 'On_game_end'), self)
	ListenToGameEvent("round_start", Dynamic_Wrap(dotacraft, 'On_round_start'), self)
	ListenToGameEvent("round_end", Dynamic_Wrap(dotacraft, 'On_round_end'), self)
	ListenToGameEvent("round_start_pre_entity", Dynamic_Wrap(dotacraft, 'On_round_start_pre_entity'), self)
	ListenToGameEvent("teamplay_round_start", Dynamic_Wrap(dotacraft, 'On_teamplay_round_start'), self)
	ListenToGameEvent("hostname_changed", Dynamic_Wrap(dotacraft, 'On_hostname_changed'), self)
	ListenToGameEvent("difficulty_changed", Dynamic_Wrap(dotacraft, 'On_difficulty_changed'), self)
	ListenToGameEvent("finale_start", Dynamic_Wrap(dotacraft, 'On_finale_start'), self)
	ListenToGameEvent("game_message", Dynamic_Wrap(dotacraft, 'On_game_message'), self)
	ListenToGameEvent("break_breakable", Dynamic_Wrap(dotacraft, 'On_break_breakable'), self)
	ListenToGameEvent("break_prop", Dynamic_Wrap(dotacraft, 'On_break_prop'), self)
	ListenToGameEvent("npc_spawned", Dynamic_Wrap(dotacraft, 'On_npc_spawned'), self)
	ListenToGameEvent("npc_replaced", Dynamic_Wrap(dotacraft, 'On_npc_replaced'), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(dotacraft, 'On_entity_killed'), self)
	--ListenToGameEvent("entity_hurt", Dynamic_Wrap(dotacraft, 'On_entity_hurt'), self)
	ListenToGameEvent("bonus_updated", Dynamic_Wrap(dotacraft, 'On_bonus_updated'), self)
	ListenToGameEvent("player_stats_updated", Dynamic_Wrap(dotacraft, 'On_player_stats_updated'), self)
	ListenToGameEvent("achievement_event", Dynamic_Wrap(dotacraft, 'On_achievement_event'), self)
	ListenToGameEvent("achievement_earned", Dynamic_Wrap(dotacraft, 'On_achievement_earned'), self)
	ListenToGameEvent("achievement_write_failed", Dynamic_Wrap(dotacraft, 'On_achievement_write_failed'), self)
	ListenToGameEvent("physgun_pickup", Dynamic_Wrap(dotacraft, 'On_physgun_pickup'), self)
	ListenToGameEvent("flare_ignite_npc", Dynamic_Wrap(dotacraft, 'On_flare_ignite_npc'), self)
	ListenToGameEvent("helicopter_grenade_punt_miss", Dynamic_Wrap(dotacraft, 'On_helicopter_grenade_punt_miss'), self)
	ListenToGameEvent("user_data_downloaded", Dynamic_Wrap(dotacraft, 'On_user_data_downloaded'), self)
	ListenToGameEvent("ragdoll_dissolved", Dynamic_Wrap(dotacraft, 'On_ragdoll_dissolved'), self)
	ListenToGameEvent("gameinstructor_draw", Dynamic_Wrap(dotacraft, 'On_gameinstructor_draw'), self)
	ListenToGameEvent("gameinstructor_nodraw", Dynamic_Wrap(dotacraft, 'On_gameinstructor_nodraw'), self)
	ListenToGameEvent("map_transition", Dynamic_Wrap(dotacraft, 'On_map_transition'), self)
	ListenToGameEvent("instructor_server_hint_create", Dynamic_Wrap(dotacraft, 'On_instructor_server_hint_create'), self)
	ListenToGameEvent("instructor_server_hint_stop", Dynamic_Wrap(dotacraft, 'On_instructor_server_hint_stop'), self)
	ListenToGameEvent("chat_new_message", Dynamic_Wrap(dotacraft, 'On_chat_new_message'), self)
	ListenToGameEvent("chat_members_changed", Dynamic_Wrap(dotacraft, 'On_chat_members_changed'), self)
	ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(dotacraft, 'On_game_rules_state_change'), self)
	ListenToGameEvent("inventory_updated", Dynamic_Wrap(dotacraft, 'On_inventory_updated'), self)
	ListenToGameEvent("cart_updated", Dynamic_Wrap(dotacraft, 'On_cart_updated'), self)
	ListenToGameEvent("store_pricesheet_updated", Dynamic_Wrap(dotacraft, 'On_store_pricesheet_updated'), self)
	ListenToGameEvent("gc_connected", Dynamic_Wrap(dotacraft, 'On_gc_connected'), self)
	ListenToGameEvent("item_schema_initialized", Dynamic_Wrap(dotacraft, 'On_item_schema_initialized'), self)
	ListenToGameEvent("drop_rate_modified", Dynamic_Wrap(dotacraft, 'On_drop_rate_modified'), self)
	ListenToGameEvent("event_ticket_modified", Dynamic_Wrap(dotacraft, 'On_event_ticket_modified'), self)
	ListenToGameEvent("modifier_event", Dynamic_Wrap(dotacraft, 'On_modifier_event'), self)
	ListenToGameEvent("dota_player_kill", Dynamic_Wrap(dotacraft, 'On_dota_player_kill'), self)
	ListenToGameEvent("dota_player_deny", Dynamic_Wrap(dotacraft, 'On_dota_player_deny'), self)
	ListenToGameEvent("dota_barracks_kill", Dynamic_Wrap(dotacraft, 'On_dota_barracks_kill'), self)
	ListenToGameEvent("dota_tower_kill", Dynamic_Wrap(dotacraft, 'On_dota_tower_kill'), self)
	ListenToGameEvent("dota_roshan_kill", Dynamic_Wrap(dotacraft, 'On_dota_roshan_kill'), self)
	ListenToGameEvent("dota_courier_lost", Dynamic_Wrap(dotacraft, 'On_dota_courier_lost'), self)
	ListenToGameEvent("dota_courier_respawned", Dynamic_Wrap(dotacraft, 'On_dota_courier_respawned'), self)
	ListenToGameEvent("dota_glyph_used", Dynamic_Wrap(dotacraft, 'On_dota_glyph_used'), self)
	ListenToGameEvent("dota_super_creeps", Dynamic_Wrap(dotacraft, 'On_dota_super_creeps'), self)
	ListenToGameEvent("dota_item_purchase", Dynamic_Wrap(dotacraft, 'On_dota_item_purchase'), self)
	ListenToGameEvent("dota_item_gifted", Dynamic_Wrap(dotacraft, 'On_dota_item_gifted'), self)
	ListenToGameEvent("dota_rune_pickup", Dynamic_Wrap(dotacraft, 'On_dota_rune_pickup'), self)
	ListenToGameEvent("dota_rune_spotted", Dynamic_Wrap(dotacraft, 'On_dota_rune_spotted'), self)
	ListenToGameEvent("dota_item_spotted", Dynamic_Wrap(dotacraft, 'On_dota_item_spotted'), self)
	ListenToGameEvent("dota_no_battle_points", Dynamic_Wrap(dotacraft, 'On_dota_no_battle_points'), self)
	ListenToGameEvent("dota_chat_informational", Dynamic_Wrap(dotacraft, 'On_dota_chat_informational'), self)
	ListenToGameEvent("dota_action_item", Dynamic_Wrap(dotacraft, 'On_dota_action_item'), self)
	ListenToGameEvent("dota_chat_ban_notification", Dynamic_Wrap(dotacraft, 'On_dota_chat_ban_notification'), self)
	ListenToGameEvent("dota_chat_event", Dynamic_Wrap(dotacraft, 'On_dota_chat_event'), self)
	ListenToGameEvent("dota_chat_timed_reward", Dynamic_Wrap(dotacraft, 'On_dota_chat_timed_reward'), self)
	ListenToGameEvent("dota_pause_event", Dynamic_Wrap(dotacraft, 'On_dota_pause_event'), self)
	ListenToGameEvent("dota_chat_kill_streak", Dynamic_Wrap(dotacraft, 'On_dota_chat_kill_streak'), self)
	ListenToGameEvent("dota_chat_first_blood", Dynamic_Wrap(dotacraft, 'On_dota_chat_first_blood'), self)
	ListenToGameEvent("dota_player_update_hero_selection", Dynamic_Wrap(dotacraft, 'On_dota_player_update_hero_selection'), self)
	ListenToGameEvent("dota_player_update_selected_unit", Dynamic_Wrap(dotacraft, 'On_dota_player_update_selected_unit'), self)
	ListenToGameEvent("dota_player_update_query_unit", Dynamic_Wrap(dotacraft, 'On_dota_player_update_query_unit'), self)
	ListenToGameEvent("dota_player_update_killcam_unit", Dynamic_Wrap(dotacraft, 'On_dota_player_update_killcam_unit'), self)
	ListenToGameEvent("dota_player_take_tower_damage", Dynamic_Wrap(dotacraft, 'On_dota_player_take_tower_damage'), self)
	ListenToGameEvent("dota_hud_error_message", Dynamic_Wrap(dotacraft, 'On_dota_hud_error_message'), self)
	ListenToGameEvent("dota_action_success", Dynamic_Wrap(dotacraft, 'On_dota_action_success'), self)
	ListenToGameEvent("dota_starting_position_changed", Dynamic_Wrap(dotacraft, 'On_dota_starting_position_changed'), self)
	ListenToGameEvent("dota_money_changed", Dynamic_Wrap(dotacraft, 'On_dota_money_changed'), self)
	ListenToGameEvent("dota_enemy_money_changed", Dynamic_Wrap(dotacraft, 'On_dota_enemy_money_changed'), self)
	ListenToGameEvent("dota_portrait_unit_stats_changed", Dynamic_Wrap(dotacraft, 'On_dota_portrait_unit_stats_changed'), self)
	ListenToGameEvent("dota_portrait_unit_modifiers_changed", Dynamic_Wrap(dotacraft, 'On_dota_portrait_unit_modifiers_changed'), self)
	ListenToGameEvent("dota_force_portrait_update", Dynamic_Wrap(dotacraft, 'On_dota_force_portrait_update'), self)
	ListenToGameEvent("dota_inventory_changed", Dynamic_Wrap(dotacraft, 'On_dota_inventory_changed'), self)
	ListenToGameEvent("dota_item_picked_up", Dynamic_Wrap(dotacraft, 'On_dota_item_picked_up'), self)
	ListenToGameEvent("dota_inventory_item_changed", Dynamic_Wrap(dotacraft, 'On_dota_inventory_item_changed'), self)
	ListenToGameEvent("dota_ability_changed", Dynamic_Wrap(dotacraft, 'On_dota_ability_changed'), self)
	ListenToGameEvent("dota_portrait_ability_layout_changed", Dynamic_Wrap(dotacraft, 'On_dota_portrait_ability_layout_changed'), self)
	ListenToGameEvent("dota_inventory_item_added", Dynamic_Wrap(dotacraft, 'On_dota_inventory_item_added'), self)
	ListenToGameEvent("dota_inventory_changed_query_unit", Dynamic_Wrap(dotacraft, 'On_dota_inventory_changed_query_unit'), self)
	ListenToGameEvent("dota_link_clicked", Dynamic_Wrap(dotacraft, 'On_dota_link_clicked'), self)
	ListenToGameEvent("dota_set_quick_buy", Dynamic_Wrap(dotacraft, 'On_dota_set_quick_buy'), self)
	ListenToGameEvent("dota_quick_buy_changed", Dynamic_Wrap(dotacraft, 'On_dota_quick_buy_changed'), self)
	ListenToGameEvent("dota_player_shop_changed", Dynamic_Wrap(dotacraft, 'On_dota_player_shop_changed'), self)
	ListenToGameEvent("dota_player_show_killcam", Dynamic_Wrap(dotacraft, 'On_dota_player_show_killcam'), self)
	ListenToGameEvent("dota_player_show_minikillcam", Dynamic_Wrap(dotacraft, 'On_dota_player_show_minikillcam'), self)
	ListenToGameEvent("gc_user_session_created", Dynamic_Wrap(dotacraft, 'On_gc_user_session_created'), self)
	ListenToGameEvent("team_data_updated", Dynamic_Wrap(dotacraft, 'On_team_data_updated'), self)
	ListenToGameEvent("guild_data_updated", Dynamic_Wrap(dotacraft, 'On_guild_data_updated'), self)
	ListenToGameEvent("guild_open_parties_updated", Dynamic_Wrap(dotacraft, 'On_guild_open_parties_updated'), self)
	ListenToGameEvent("fantasy_updated", Dynamic_Wrap(dotacraft, 'On_fantasy_updated'), self)
	ListenToGameEvent("fantasy_league_changed", Dynamic_Wrap(dotacraft, 'On_fantasy_league_changed'), self)
	ListenToGameEvent("fantasy_score_info_changed", Dynamic_Wrap(dotacraft, 'On_fantasy_score_info_changed'), self)
	ListenToGameEvent("player_info_updated", Dynamic_Wrap(dotacraft, 'On_player_info_updated'), self)
	ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(dotacraft, 'On_game_rules_state_change'), self)
	ListenToGameEvent("match_history_updated", Dynamic_Wrap(dotacraft, 'On_match_history_updated'), self)
	ListenToGameEvent("match_details_updated", Dynamic_Wrap(dotacraft, 'On_match_details_updated'), self)
	ListenToGameEvent("live_games_updated", Dynamic_Wrap(dotacraft, 'On_live_games_updated'), self)
	ListenToGameEvent("recent_matches_updated", Dynamic_Wrap(dotacraft, 'On_recent_matches_updated'), self)
	ListenToGameEvent("news_updated", Dynamic_Wrap(dotacraft, 'On_news_updated'), self)
	ListenToGameEvent("persona_updated", Dynamic_Wrap(dotacraft, 'On_persona_updated'), self)
	ListenToGameEvent("tournament_state_updated", Dynamic_Wrap(dotacraft, 'On_tournament_state_updated'), self)
	ListenToGameEvent("party_updated", Dynamic_Wrap(dotacraft, 'On_party_updated'), self)
	ListenToGameEvent("lobby_updated", Dynamic_Wrap(dotacraft, 'On_lobby_updated'), self)
	ListenToGameEvent("dashboard_caches_cleared", Dynamic_Wrap(dotacraft, 'On_dashboard_caches_cleared'), self)
	ListenToGameEvent("last_hit", Dynamic_Wrap(dotacraft, 'On_last_hit'), self)
	ListenToGameEvent("player_completed_game", Dynamic_Wrap(dotacraft, 'On_player_completed_game'), self)
	ListenToGameEvent("dota_combatlog", Dynamic_Wrap(dotacraft, 'On_dota_combatlog'), self)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(dotacraft, 'On_player_reconnected'), self)
	ListenToGameEvent("nommed_tree", Dynamic_Wrap(dotacraft, 'On_nommed_tree'), self)
	ListenToGameEvent("dota_rune_activated_server", Dynamic_Wrap(dotacraft, 'On_dota_rune_activated_server'), self)
	ListenToGameEvent("dota_player_gained_level", Dynamic_Wrap(dotacraft, 'On_dota_player_gained_level'), self)
	ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap(dotacraft, 'On_dota_player_pick_hero'), self)
	ListenToGameEvent("dota_player_learned_ability", Dynamic_Wrap(dotacraft, 'On_dota_player_learned_ability'), self)
	ListenToGameEvent("dota_player_used_ability", Dynamic_Wrap(dotacraft, 'On_dota_player_used_ability'), self)
	ListenToGameEvent("dota_non_player_used_ability", Dynamic_Wrap(dotacraft, 'On_dota_non_player_used_ability'), self)
	ListenToGameEvent("dota_ability_channel_finished", Dynamic_Wrap(dotacraft, 'On_dota_ability_channel_finished'), self)
	ListenToGameEvent("dota_holdout_revive_complete", Dynamic_Wrap(dotacraft, 'On_dota_holdout_revive_complete'), self)
	ListenToGameEvent("dota_player_killed", Dynamic_Wrap(dotacraft, 'On_dota_player_killed'), self)
	ListenToGameEvent("bindpanel_open", Dynamic_Wrap(dotacraft, 'On_bindpanel_open'), self)
	ListenToGameEvent("bindpanel_close", Dynamic_Wrap(dotacraft, 'On_bindpanel_close'), self)
	ListenToGameEvent("keybind_changed", Dynamic_Wrap(dotacraft, 'On_keybind_changed'), self)
	ListenToGameEvent("dota_item_drag_begin", Dynamic_Wrap(dotacraft, 'On_dota_item_drag_begin'), self)
	ListenToGameEvent("dota_item_drag_end", Dynamic_Wrap(dotacraft, 'On_dota_item_drag_end'), self)
	ListenToGameEvent("dota_shop_item_drag_begin", Dynamic_Wrap(dotacraft, 'On_dota_shop_item_drag_begin'), self)
	ListenToGameEvent("dota_shop_item_drag_end", Dynamic_Wrap(dotacraft, 'On_dota_shop_item_drag_end'), self)
	ListenToGameEvent("dota_item_purchased", Dynamic_Wrap(dotacraft, 'On_dota_item_purchased'), self)
	ListenToGameEvent("dota_item_used", Dynamic_Wrap(dotacraft, 'On_dota_item_used'), self)
	ListenToGameEvent("dota_item_auto_purchase", Dynamic_Wrap(dotacraft, 'On_dota_item_auto_purchase'), self)
	ListenToGameEvent("dota_unit_event", Dynamic_Wrap(dotacraft, 'On_dota_unit_event'), self)
	ListenToGameEvent("dota_quest_started", Dynamic_Wrap(dotacraft, 'On_dota_quest_started'), self)
	ListenToGameEvent("dota_quest_completed", Dynamic_Wrap(dotacraft, 'On_dota_quest_completed'), self)
	ListenToGameEvent("gameui_activated", Dynamic_Wrap(dotacraft, 'On_gameui_activated'), self)
	ListenToGameEvent("gameui_hidden", Dynamic_Wrap(dotacraft, 'On_gameui_hidden'), self)
	ListenToGameEvent("player_fullyjoined", Dynamic_Wrap(dotacraft, 'On_player_fullyjoined'), self)
	ListenToGameEvent("dota_spectate_hero", Dynamic_Wrap(dotacraft, 'On_dota_spectate_hero'), self)
	ListenToGameEvent("dota_match_done", Dynamic_Wrap(dotacraft, 'On_dota_match_done'), self)
	ListenToGameEvent("dota_match_done_client", Dynamic_Wrap(dotacraft, 'On_dota_match_done_client'), self)
	ListenToGameEvent("set_instructor_group_enabled", Dynamic_Wrap(dotacraft, 'On_set_instructor_group_enabled'), self)
	ListenToGameEvent("joined_chat_channel", Dynamic_Wrap(dotacraft, 'On_joined_chat_channel'), self)
	ListenToGameEvent("left_chat_channel", Dynamic_Wrap(dotacraft, 'On_left_chat_channel'), self)
	ListenToGameEvent("gc_chat_channel_list_updated", Dynamic_Wrap(dotacraft, 'On_gc_chat_channel_list_updated'), self)
	ListenToGameEvent("today_messages_updated", Dynamic_Wrap(dotacraft, 'On_today_messages_updated'), self)
	ListenToGameEvent("file_downloaded", Dynamic_Wrap(dotacraft, 'On_file_downloaded'), self)
	ListenToGameEvent("player_report_counts_updated", Dynamic_Wrap(dotacraft, 'On_player_report_counts_updated'), self)
	ListenToGameEvent("scaleform_file_download_complete", Dynamic_Wrap(dotacraft, 'On_scaleform_file_download_complete'), self)
	ListenToGameEvent("item_purchased", Dynamic_Wrap(dotacraft, 'On_item_purchased'), self)
	ListenToGameEvent("gc_mismatched_version", Dynamic_Wrap(dotacraft, 'On_gc_mismatched_version'), self)
	ListenToGameEvent("demo_skip", Dynamic_Wrap(dotacraft, 'On_demo_skip'), self)
	ListenToGameEvent("demo_start", Dynamic_Wrap(dotacraft, 'On_demo_start'), self)
	ListenToGameEvent("demo_stop", Dynamic_Wrap(dotacraft, 'On_demo_stop'), self)
	ListenToGameEvent("map_shutdown", Dynamic_Wrap(dotacraft, 'On_map_shutdown'), self)
	ListenToGameEvent("dota_workshop_fileselected", Dynamic_Wrap(dotacraft, 'On_dota_workshop_fileselected'), self)
	ListenToGameEvent("dota_workshop_filecanceled", Dynamic_Wrap(dotacraft, 'On_dota_workshop_filecanceled'), self)
	ListenToGameEvent("rich_presence_updated", Dynamic_Wrap(dotacraft, 'On_rich_presence_updated'), self)
	ListenToGameEvent("dota_hero_random", Dynamic_Wrap(dotacraft, 'On_dota_hero_random'), self)
	ListenToGameEvent("dota_rd_chat_turn", Dynamic_Wrap(dotacraft, 'On_dota_rd_chat_turn'), self)
	ListenToGameEvent("dota_favorite_heroes_updated", Dynamic_Wrap(dotacraft, 'On_dota_favorite_heroes_updated'), self)
	ListenToGameEvent("profile_closed", Dynamic_Wrap(dotacraft, 'On_profile_closed'), self)
	ListenToGameEvent("item_preview_closed", Dynamic_Wrap(dotacraft, 'On_item_preview_closed'), self)
	ListenToGameEvent("dashboard_switched_section", Dynamic_Wrap(dotacraft, 'On_dashboard_switched_section'), self)
	ListenToGameEvent("dota_tournament_item_event", Dynamic_Wrap(dotacraft, 'On_dota_tournament_item_event'), self)
	ListenToGameEvent("dota_hero_swap", Dynamic_Wrap(dotacraft, 'On_dota_hero_swap'), self)
	ListenToGameEvent("dota_reset_suggested_items", Dynamic_Wrap(dotacraft, 'On_dota_reset_suggested_items'), self)
	ListenToGameEvent("halloween_high_score_received", Dynamic_Wrap(dotacraft, 'On_halloween_high_score_received'), self)
	ListenToGameEvent("halloween_phase_end", Dynamic_Wrap(dotacraft, 'On_halloween_phase_end'), self)
	ListenToGameEvent("halloween_high_score_request_failed", Dynamic_Wrap(dotacraft, 'On_halloween_high_score_request_failed'), self)
	ListenToGameEvent("dota_hud_skin_changed", Dynamic_Wrap(dotacraft, 'On_dota_hud_skin_changed'), self)
	ListenToGameEvent("dota_inventory_player_got_item", Dynamic_Wrap(dotacraft, 'On_dota_inventory_player_got_item'), self)
	ListenToGameEvent("player_is_experienced", Dynamic_Wrap(dotacraft, 'On_player_is_experienced'), self)
	ListenToGameEvent("player_is_notexperienced", Dynamic_Wrap(dotacraft, 'On_player_is_notexperienced'), self)
	ListenToGameEvent("dota_tutorial_lesson_start", Dynamic_Wrap(dotacraft, 'On_dota_tutorial_lesson_start'), self)
	ListenToGameEvent("map_location_updated", Dynamic_Wrap(dotacraft, 'On_map_location_updated'), self)
	ListenToGameEvent("richpresence_custom_updated", Dynamic_Wrap(dotacraft, 'On_richpresence_custom_updated'), self)
	ListenToGameEvent("game_end_visible", Dynamic_Wrap(dotacraft, 'On_game_end_visible'), self)
	ListenToGameEvent("antiaddiction_update", Dynamic_Wrap(dotacraft, 'On_antiaddiction_update'), self)
	ListenToGameEvent("highlight_hud_element", Dynamic_Wrap(dotacraft, 'On_highlight_hud_element'), self)
	ListenToGameEvent("hide_highlight_hud_element", Dynamic_Wrap(dotacraft, 'On_hide_highlight_hud_element'), self)
	ListenToGameEvent("intro_video_finished", Dynamic_Wrap(dotacraft, 'On_intro_video_finished'), self)
	ListenToGameEvent("matchmaking_status_visibility_changed", Dynamic_Wrap(dotacraft, 'On_matchmaking_status_visibility_changed'), self)
	ListenToGameEvent("practice_lobby_visibility_changed", Dynamic_Wrap(dotacraft, 'On_practice_lobby_visibility_changed'), self)
	ListenToGameEvent("dota_courier_transfer_item", Dynamic_Wrap(dotacraft, 'On_dota_courier_transfer_item'), self)
	ListenToGameEvent("full_ui_unlocked", Dynamic_Wrap(dotacraft, 'On_full_ui_unlocked'), self)
	ListenToGameEvent("client_connectionless_packet", Dynamic_Wrap(dotacraft, 'On_client_connectionless_packet'), self)
	ListenToGameEvent("hero_selector_preview_set", Dynamic_Wrap(dotacraft, 'On_hero_selector_preview_set'), self)
	ListenToGameEvent("antiaddiction_toast", Dynamic_Wrap(dotacraft, 'On_antiaddiction_toast'), self)
	ListenToGameEvent("hero_picker_shown", Dynamic_Wrap(dotacraft, 'On_hero_picker_shown'), self)
	ListenToGameEvent("hero_picker_hidden", Dynamic_Wrap(dotacraft, 'On_hero_picker_hidden'), self)
	ListenToGameEvent("dota_local_quickbuy_changed", Dynamic_Wrap(dotacraft, 'On_dota_local_quickbuy_changed'), self)
	ListenToGameEvent("show_center_message", Dynamic_Wrap(dotacraft, 'On_show_center_message'), self)
	ListenToGameEvent("hud_flip_changed", Dynamic_Wrap(dotacraft, 'On_hud_flip_changed'), self)
	ListenToGameEvent("frosty_points_updated", Dynamic_Wrap(dotacraft, 'On_frosty_points_updated'), self)
	ListenToGameEvent("defeated", Dynamic_Wrap(dotacraft, 'On_defeated'), self)
	ListenToGameEvent("reset_defeated", Dynamic_Wrap(dotacraft, 'On_reset_defeated'), self)
	ListenToGameEvent("booster_state_updated", Dynamic_Wrap(dotacraft, 'On_booster_state_updated'), self)
	ListenToGameEvent("event_points_updated", Dynamic_Wrap(dotacraft, 'On_event_points_updated'), self)
	ListenToGameEvent("local_player_event_points", Dynamic_Wrap(dotacraft, 'On_local_player_event_points'), self)
	ListenToGameEvent("custom_game_difficulty", Dynamic_Wrap(dotacraft, 'On_custom_game_difficulty'), self)
	ListenToGameEvent("tree_cut", Dynamic_Wrap(dotacraft, 'On_tree_cut'), self)
	ListenToGameEvent("ugc_details_arrived", Dynamic_Wrap(dotacraft, 'On_ugc_details_arrived'), self)
	ListenToGameEvent("ugc_subscribed", Dynamic_Wrap(dotacraft, 'On_ugc_subscribed'), self)
	ListenToGameEvent("ugc_unsubscribed", Dynamic_Wrap(dotacraft, 'On_ugc_unsubscribed'), self)
	ListenToGameEvent("prizepool_received", Dynamic_Wrap(dotacraft, 'On_prizepool_received'), self)
	ListenToGameEvent("microtransaction_success", Dynamic_Wrap(dotacraft, 'On_microtransaction_success'), self)
	ListenToGameEvent("dota_rubick_ability_steal", Dynamic_Wrap(dotacraft, 'On_dota_rubick_ability_steal'), self)
	ListenToGameEvent("compendium_event_actions_loaded", Dynamic_Wrap(dotacraft, 'On_compendium_event_actions_loaded'), self)
	ListenToGameEvent("compendium_selections_loaded", Dynamic_Wrap(dotacraft, 'On_compendium_selections_loaded'), self)
	ListenToGameEvent("compendium_set_selection_failed", Dynamic_Wrap(dotacraft, 'On_compendium_set_selection_failed'), self)
	ListenToGameEvent("community_cached_names_updated", Dynamic_Wrap(dotacraft, 'On_community_cached_names_updated'), self)
	ListenToGameEvent("dota_team_kill_credit", Dynamic_Wrap(dotacraft, 'On_dota_team_kill_credit'), self)
end

function dotacraft:On_team_info(data)
  print("[DOTACRAFT] team_info")
  PrintTable(data)
end


function dotacraft:On_team_score(data)
  print("[DOTACRAFT] team_score")
  PrintTable(data)
end


function dotacraft:On_teamplay_broadcast_audio(data)
  print("[DOTACRAFT] teamplay_broadcast_audio")
  PrintTable(data)
end


function dotacraft:On_player_team(data)
  print("[DOTACRAFT] player_team")
  PrintTable(data)
end


function dotacraft:On_player_class(data)
  print("[DOTACRAFT] player_class")
  PrintTable(data)
end


function dotacraft:On_player_death (data)
  print("[DOTACRAFT] player_death")
  PrintTable(data)
end


function dotacraft:On_player_hurt (data)
  print("[DOTACRAFT] player_hurt")
  PrintTable(data)
end


function dotacraft:On_player_chat (data)
  print("[DOTACRAFT] player_chat")
  PrintTable(data)
end


function dotacraft:On_player_score(data)
  print("[DOTACRAFT] player_score")
  PrintTable(data)
end


function dotacraft:On_player_spawn(data)
  print("[DOTACRAFT] player_spawn")
  PrintTable(data)
end


function dotacraft:On_player_shoot(data)
  print("[DOTACRAFT] player_shoot")
  PrintTable(data)
end


function dotacraft:On_player_use(data)
  print("[DOTACRAFT] player_use")
  PrintTable(data)
end


function dotacraft:On_player_changename(data)
  print("[DOTACRAFT] player_changename")
  PrintTable(data)
end


function dotacraft:On_player_hintmessage(data)
  print("[DOTACRAFT] player_hintmessage")
  PrintTable(data)
end


function dotacraft:On_player_reconnected (data)
  print("[DOTACRAFT] player_reconnected")
  PrintTable(data)
end


function dotacraft:On_game_init(data)
  print("[DOTACRAFT] game_init")
  PrintTable(data)
end


function dotacraft:On_game_newmap(data)
  print("[DOTACRAFT] game_newmap")
  PrintTable(data)
end


function dotacraft:On_game_start(data)
  print("[DOTACRAFT] game_start")
  PrintTable(data)
end


function dotacraft:On_game_end(data)
  print("[DOTACRAFT] game_end")
  PrintTable(data)
end


function dotacraft:On_round_start(data)
  print("[DOTACRAFT] round_start")
  PrintTable(data)
end


function dotacraft:On_round_end(data)
  print("[DOTACRAFT] round_end")
  PrintTable(data)
end


function dotacraft:On_round_start_pre_entity(data)
  print("[DOTACRAFT] round_start_pre_entity")
  PrintTable(data)
end


function dotacraft:On_teamplay_round_start(data)
  print("[DOTACRAFT] teamplay_round_start")
  PrintTable(data)
end


function dotacraft:On_hostname_changed(data)
  print("[DOTACRAFT] hostname_changed")
  PrintTable(data)
end


function dotacraft:On_difficulty_changed(data)
  print("[DOTACRAFT] difficulty_changed")
  PrintTable(data)
end


function dotacraft:On_finale_start(data)
  print("[DOTACRAFT] finale_start")
  PrintTable(data)
end


function dotacraft:On_game_message(data)
  print("[DOTACRAFT] game_message")
  PrintTable(data)
end


function dotacraft:On_break_breakable(data)
  print("[DOTACRAFT] break_breakable")
  PrintTable(data)
end


function dotacraft:On_break_prop(data)
  print("[DOTACRAFT] break_prop")
  PrintTable(data)
end


function dotacraft:On_npc_spawned(data)
  print("[DOTACRAFT] npc_spawned")
  PrintTable(data)
end


function dotacraft:On_npc_replaced(data)
  print("[DOTACRAFT] npc_replaced")
  PrintTable(data)
end


function dotacraft:On_entity_killed(data)
  print("[DOTACRAFT] entity_killed")
  PrintTable(data)
end


function dotacraft:On_entity_hurt(data)
  print("[DOTACRAFT] entity_hurt")
  PrintTable(data)
end


function dotacraft:On_bonus_updated(data)
  print("[DOTACRAFT] bonus_updated")
  PrintTable(data)
end


function dotacraft:On_player_stats_updated(data)
  print("[DOTACRAFT] player_stats_updated")
  PrintTable(data)
end


function dotacraft:On_achievement_event(data)
  print("[DOTACRAFT] achievement_event")
  PrintTable(data)
end


function dotacraft:On_achievement_earned(data)
  print("[DOTACRAFT] achievement_earned")
  PrintTable(data)
end


function dotacraft:On_achievement_write_failed(data)
  print("[DOTACRAFT] achievement_write_failed")
  PrintTable(data)
end


function dotacraft:On_physgun_pickup(data)
  print("[DOTACRAFT] physgun_pickup")
  PrintTable(data)
end


function dotacraft:On_flare_ignite_npc(data)
  print("[DOTACRAFT] flare_ignite_npc")
  PrintTable(data)
end


function dotacraft:On_helicopter_grenade_punt_miss(data)
  print("[DOTACRAFT] helicopter_grenade_punt_miss")
  PrintTable(data)
end


function dotacraft:On_user_data_downloaded(data)
  print("[DOTACRAFT] user_data_downloaded")
  PrintTable(data)
end


function dotacraft:On_ragdoll_dissolved(data)
  print("[DOTACRAFT] ragdoll_dissolved")
  PrintTable(data)
end


function dotacraft:On_gameinstructor_draw(data)
  print("[DOTACRAFT] gameinstructor_draw")
  PrintTable(data)
end


function dotacraft:On_gameinstructor_nodraw(data)
  print("[DOTACRAFT] gameinstructor_nodraw")
  PrintTable(data)
end


function dotacraft:On_map_transition(data)
  print("[DOTACRAFT] map_transition")
  PrintTable(data)
end


function dotacraft:On_instructor_server_hint_create(data)
  print("[DOTACRAFT] instructor_server_hint_create")
  PrintTable(data)
end


function dotacraft:On_instructor_server_hint_stop(data)
  print("[DOTACRAFT] instructor_server_hint_stop")
  PrintTable(data)
end


function dotacraft:On_chat_new_message(data)
  print("[DOTACRAFT] chat_new_message")
  PrintTable(data)
end


function dotacraft:On_chat_members_changed(data)
  print("[DOTACRAFT] chat_members_changed")
  PrintTable(data)
end


function dotacraft:On_game_rules_state_change(data)
  print("[DOTACRAFT] game_rules_state_change")
  PrintTable(data)
end


function dotacraft:On_inventory_updated(data)
  print("[DOTACRAFT] inventory_updated")
  PrintTable(data)
end


function dotacraft:On_cart_updated(data)
  print("[DOTACRAFT] cart_updated")
  PrintTable(data)
end


function dotacraft:On_store_pricesheet_updated(data)
  print("[DOTACRAFT] store_pricesheet_updated")
  PrintTable(data)
end


function dotacraft:On_gc_connected(data)
  print("[DOTACRAFT] gc_connected")
  PrintTable(data)
end


function dotacraft:On_item_schema_initialized(data)
  print("[DOTACRAFT] item_schema_initialized")
  PrintTable(data)
end


function dotacraft:On_drop_rate_modified(data)
  print("[DOTACRAFT] drop_rate_modified")
  PrintTable(data)
end


function dotacraft:On_event_ticket_modified(data)
  print("[DOTACRAFT] event_ticket_modified")
  PrintTable(data)
end


function dotacraft:On_modifier_event(data)
  print("[DOTACRAFT] modifier_event")
  PrintTable(data)
end


function dotacraft:On_dota_player_kill(data)
  print("[DOTACRAFT] dota_player_kill")
  PrintTable(data)
end


function dotacraft:On_dota_player_deny(data)
  print("[DOTACRAFT] dota_player_deny")
  PrintTable(data)
end


function dotacraft:On_dota_barracks_kill(data)
  print("[DOTACRAFT] dota_barracks_kill")
  PrintTable(data)
end


function dotacraft:On_dota_tower_kill(data)
  print("[DOTACRAFT] dota_tower_kill")
  PrintTable(data)
end


function dotacraft:On_dota_roshan_kill(data)
  print("[DOTACRAFT] dota_roshan_kill")
  PrintTable(data)
end


function dotacraft:On_dota_courier_lost(data)
  print("[DOTACRAFT] dota_courier_lost")
  PrintTable(data)
end


function dotacraft:On_dota_courier_respawned(data)
  print("[DOTACRAFT] dota_courier_respawned")
  PrintTable(data)
end


function dotacraft:On_dota_glyph_used(data)
  print("[DOTACRAFT] dota_glyph_used")
  PrintTable(data)
end


function dotacraft:On_dota_super_creeps(data)
  print("[DOTACRAFT] dota_super_creeps")
  PrintTable(data)
end


function dotacraft:On_dota_item_purchase(data)
  print("[DOTACRAFT] dota_item_purchase")
  PrintTable(data)
end


function dotacraft:On_dota_item_gifted(data)
  print("[DOTACRAFT] dota_item_gifted")
  PrintTable(data)
end


function dotacraft:On_dota_rune_pickup(data)
  print("[DOTACRAFT] dota_rune_pickup")
  PrintTable(data)
end


function dotacraft:On_dota_rune_spotted(data)
  print("[DOTACRAFT] dota_rune_spotted")
  PrintTable(data)
end


function dotacraft:On_dota_item_spotted(data)
  print("[DOTACRAFT] dota_item_spotted")
  PrintTable(data)
end


function dotacraft:On_dota_no_battle_points(data)
  print("[DOTACRAFT] dota_no_battle_points")
  PrintTable(data)
end


function dotacraft:On_dota_chat_informational(data)
  print("[DOTACRAFT] dota_chat_informational")
  PrintTable(data)
end


function dotacraft:On_dota_action_item(data)
  print("[DOTACRAFT] dota_action_item")
  PrintTable(data)
end


function dotacraft:On_dota_chat_ban_notification(data)
  print("[DOTACRAFT] dota_chat_ban_notification")
  PrintTable(data)
end


function dotacraft:On_dota_chat_event(data)
  print("[DOTACRAFT] dota_chat_event")
  PrintTable(data)
end


function dotacraft:On_dota_chat_timed_reward(data)
  print("[DOTACRAFT] dota_chat_timed_reward")
  PrintTable(data)
end


function dotacraft:On_dota_pause_event(data)
  print("[DOTACRAFT] dota_pause_event")
  PrintTable(data)
end


function dotacraft:On_dota_chat_kill_streak(data)
  print("[DOTACRAFT] dota_chat_kill_streak")
  PrintTable(data)
end


function dotacraft:On_dota_chat_first_blood(data)
  print("[DOTACRAFT] dota_chat_first_blood")
  PrintTable(data)
end


function dotacraft:On_dota_player_update_hero_selection(data)
  print("[DOTACRAFT] dota_player_update_hero_selection")
  PrintTable(data)
end


function dotacraft:On_dota_player_update_selected_unit(data)
  print("[DOTACRAFT] dota_player_update_selected_unit")
  PrintTable(data)
end


function dotacraft:On_dota_player_update_query_unit(data)
  print("[DOTACRAFT] dota_player_update_query_unit")
  PrintTable(data)
end


function dotacraft:On_dota_player_update_killcam_unit(data)
  print("[DOTACRAFT] dota_player_update_killcam_unit")
  PrintTable(data)
end


function dotacraft:On_dota_player_take_tower_damage(data)
  print("[DOTACRAFT] dota_player_take_tower_damage")
  PrintTable(data)
end


function dotacraft:On_dota_hud_error_message(data)
  print("[DOTACRAFT] dota_hud_error_message")
  PrintTable(data)
end


function dotacraft:On_dota_action_success(data)
  print("[DOTACRAFT] dota_action_success")
  PrintTable(data)
end


function dotacraft:On_dota_starting_position_changed(data)
  print("[DOTACRAFT] dota_starting_position_changed")
  PrintTable(data)
end


function dotacraft:On_dota_money_changed(data)
  print("[DOTACRAFT] dota_money_changed")
  PrintTable(data)
end


function dotacraft:On_dota_enemy_money_changed(data)
  print("[DOTACRAFT] dota_enemy_money_changed")
  PrintTable(data)
end


function dotacraft:On_dota_portrait_unit_stats_changed(data)
  print("[DOTACRAFT] dota_portrait_unit_stats_changed")
  PrintTable(data)
end


function dotacraft:On_dota_portrait_unit_modifiers_changed(data)
  print("[DOTACRAFT] dota_portrait_unit_modifiers_changed")
  PrintTable(data)
end


function dotacraft:On_dota_force_portrait_update(data)
  print("[DOTACRAFT] dota_force_portrait_update")
  PrintTable(data)
end


function dotacraft:On_dota_inventory_changed(data)
  print("[DOTACRAFT] dota_inventory_changed")
  PrintTable(data)
end


function dotacraft:On_dota_item_picked_up(data)
  print("[DOTACRAFT] dota_item_picked_up")
  PrintTable(data)
end


function dotacraft:On_dota_inventory_item_changed(data)
  print("[DOTACRAFT] dota_inventory_item_changed")
  PrintTable(data)
end


function dotacraft:On_dota_ability_changed(data)
  print("[DOTACRAFT] dota_ability_changed")
  PrintTable(data)
end


function dotacraft:On_dota_portrait_ability_layout_changed(data)
  print("[DOTACRAFT] dota_portrait_ability_layout_changed")
  PrintTable(data)
end


function dotacraft:On_dota_inventory_item_added(data)
  print("[DOTACRAFT] dota_inventory_item_added")
  PrintTable(data)
end


function dotacraft:On_dota_inventory_changed_query_unit(data)
  print("[DOTACRAFT] dota_inventory_changed_query_unit")
  PrintTable(data)
end


function dotacraft:On_dota_link_clicked(data)
  print("[DOTACRAFT] dota_link_clicked")
  PrintTable(data)
end


function dotacraft:On_dota_set_quick_buy(data)
  print("[DOTACRAFT] dota_set_quick_buy")
  PrintTable(data)
end


function dotacraft:On_dota_quick_buy_changed(data)
  print("[DOTACRAFT] dota_quick_buy_changed")
  PrintTable(data)
end


function dotacraft:On_dota_player_shop_changed(data)
  print("[DOTACRAFT] dota_player_shop_changed")
  PrintTable(data)
end


function dotacraft:On_dota_player_show_killcam(data)
  print("[DOTACRAFT] dota_player_show_killcam")
  PrintTable(data)
end


function dotacraft:On_dota_player_show_minikillcam(data)
  print("[DOTACRAFT] dota_player_show_minikillcam")
  PrintTable(data)
end


function dotacraft:On_gc_user_session_created(data)
  print("[DOTACRAFT] gc_user_session_created")
  PrintTable(data)
end


function dotacraft:On_team_data_updated(data)
  print("[DOTACRAFT] team_data_updated")
  PrintTable(data)
end


function dotacraft:On_guild_data_updated(data)
  print("[DOTACRAFT] guild_data_updated")
  PrintTable(data)
end


function dotacraft:On_guild_open_parties_updated(data)
  print("[DOTACRAFT] guild_open_parties_updated")
  PrintTable(data)
end


function dotacraft:On_fantasy_updated(data)
  print("[DOTACRAFT] fantasy_updated")
  PrintTable(data)
end


function dotacraft:On_fantasy_league_changed(data)
  print("[DOTACRAFT] fantasy_league_changed")
  PrintTable(data)
end


function dotacraft:On_fantasy_score_info_changed(data)
  print("[DOTACRAFT] fantasy_score_info_changed")
  PrintTable(data)
end


function dotacraft:On_player_info_updated(data)
  print("[DOTACRAFT] player_info_updated")
  PrintTable(data)
end


function dotacraft:On_game_rules_state_change(data)
  print("[DOTACRAFT] game_rules_state_change")
  PrintTable(data)
end


function dotacraft:On_match_history_updated(data)
  print("[DOTACRAFT] match_history_updated")
  PrintTable(data)
end


function dotacraft:On_match_details_updated(data)
  print("[DOTACRAFT] match_details_updated")
  PrintTable(data)
end


function dotacraft:On_live_games_updated(data)
  print("[DOTACRAFT] live_games_updated")
  PrintTable(data)
end


function dotacraft:On_recent_matches_updated(data)
  print("[DOTACRAFT] recent_matches_updated")
  PrintTable(data)
end


function dotacraft:On_news_updated(data)
  print("[DOTACRAFT] news_updated")
  PrintTable(data)
end


function dotacraft:On_persona_updated(data)
  print("[DOTACRAFT] persona_updated")
  PrintTable(data)
end


function dotacraft:On_tournament_state_updated(data)
  print("[DOTACRAFT] tournament_state_updated")
  PrintTable(data)
end


function dotacraft:On_party_updated(data)
  print("[DOTACRAFT] party_updated")
  PrintTable(data)
end


function dotacraft:On_lobby_updated(data)
  print("[DOTACRAFT] lobby_updated")
  PrintTable(data)
end


function dotacraft:On_dashboard_caches_cleared(data)
  print("[DOTACRAFT] dashboard_caches_cleared")
  PrintTable(data)
end


function dotacraft:On_last_hit(data)
  print("[DOTACRAFT] last_hit")
  PrintTable(data)
end


function dotacraft:On_player_completed_game(data)
  print("[DOTACRAFT] player_completed_game")
  PrintTable(data)
end

function dotacraft:On_dota_combatlog(data)
  print("[DOTACRAFT] dota_combatlog")
  PrintTable(data)
end


function dotacraft:On_player_reconnected(data)
  print("[DOTACRAFT] player_reconnected")
  PrintTable(data)
end


function dotacraft:On_nommed_tree(data)
  print("[DOTACRAFT] nommed_tree")
  PrintTable(data)
end


function dotacraft:On_dota_rune_activated_server(data)
  print("[DOTACRAFT] dota_rune_activated_server")
  PrintTable(data)
end


function dotacraft:On_dota_player_gained_level(data)
  print("[DOTACRAFT] dota_player_gained_level")
  PrintTable(data)
end

function dotacraft:On_dota_player_pick_hero(data)
  print("[DOTACRAFT] dota_player_pick_hero")
  PrintTable(data)
end

function dotacraft:On_dota_player_learned_ability(data)
  print("[DOTACRAFT] dota_player_learned_ability")
  PrintTable(data)
end


function dotacraft:On_dota_player_used_ability(data)
  print("[DOTACRAFT] dota_player_used_ability")
  PrintTable(data)
end


function dotacraft:On_dota_non_player_used_ability(data)
  print("[DOTACRAFT] dota_non_player_used_ability")
  PrintTable(data)
end


function dotacraft:On_dota_ability_channel_finished(data)
  print("[DOTACRAFT] dota_ability_channel_finished")
  PrintTable(data)
end


function dotacraft:On_dota_holdout_revive_complete(data)
  print("[DOTACRAFT] dota_holdout_revive_complete")
  PrintTable(data)
end


function dotacraft:On_dota_player_killed(data)
  print("[DOTACRAFT] dota_player_killed")
  PrintTable(data)
end


function dotacraft:On_bindpanel_open(data)
  print("[DOTACRAFT] bindpanel_open")
  PrintTable(data)
end


function dotacraft:On_bindpanel_close(data)
  print("[DOTACRAFT] bindpanel_close")
  PrintTable(data)
end


function dotacraft:On_keybind_changed(data)
  print("[DOTACRAFT] keybind_changed")
  PrintTable(data)
end


function dotacraft:On_dota_item_drag_begin(data)
  print("[DOTACRAFT] dota_item_drag_begin")
  PrintTable(data)
end


function dotacraft:On_dota_item_drag_end(data)
  print("[DOTACRAFT] dota_item_drag_end")
  PrintTable(data)
end


function dotacraft:On_dota_shop_item_drag_begin(data)
  print("[DOTACRAFT] dota_shop_item_drag_begin")
  PrintTable(data)
end


function dotacraft:On_dota_shop_item_drag_end(data)
  print("[DOTACRAFT] dota_shop_item_drag_end")
  PrintTable(data)
end


function dotacraft:On_dota_item_purchased(data)
  print("[DOTACRAFT] dota_item_purchased")
  PrintTable(data)
end


function dotacraft:On_dota_item_used(data)
  print("[DOTACRAFT] dota_item_used")
  PrintTable(data)
end


function dotacraft:On_dota_item_auto_purchase(data)
  print("[DOTACRAFT] dota_item_auto_purchase")
  PrintTable(data)
end


function dotacraft:On_dota_unit_event(data)
  print("[DOTACRAFT] dota_unit_event")
  PrintTable(data)
end


function dotacraft:On_dota_quest_started(data)
  print("[DOTACRAFT] dota_quest_started")
  PrintTable(data)
end


function dotacraft:On_dota_quest_completed(data)
  print("[DOTACRAFT] dota_quest_completed")
  PrintTable(data)
end


function dotacraft:On_gameui_activated(data)
  print("[DOTACRAFT] gameui_activated")
  PrintTable(data)
end


function dotacraft:On_gameui_hidden(data)
  print("[DOTACRAFT] gameui_hidden")
  PrintTable(data)
end


function dotacraft:On_player_fullyjoined(data)
  print("[DOTACRAFT] player_fullyjoined")
  PrintTable(data)
end


function dotacraft:On_dota_spectate_hero(data)
  print("[DOTACRAFT] dota_spectate_hero")
  PrintTable(data)
end


function dotacraft:On_dota_match_done(data)
  print("[DOTACRAFT] dota_match_done")
  PrintTable(data)
end


function dotacraft:On_dota_match_done_client(data)
  print("[DOTACRAFT] dota_match_done_client")
  PrintTable(data)
end


function dotacraft:On_set_instructor_group_enabled(data)
  print("[DOTACRAFT] set_instructor_group_enabled")
  PrintTable(data)
end


function dotacraft:On_joined_chat_channel(data)
  print("[DOTACRAFT] joined_chat_channel")
  PrintTable(data)
end


function dotacraft:On_left_chat_channel(data)
  print("[DOTACRAFT] left_chat_channel")
  PrintTable(data)
end


function dotacraft:On_gc_chat_channel_list_updated(data)
  print("[DOTACRAFT] gc_chat_channel_list_updated")
  PrintTable(data)
end


function dotacraft:On_today_messages_updated(data)
  print("[DOTACRAFT] today_messages_updated")
  PrintTable(data)
end


function dotacraft:On_file_downloaded(data)
  print("[DOTACRAFT] file_downloaded")
  PrintTable(data)
end


function dotacraft:On_player_report_counts_updated(data)
  print("[DOTACRAFT] player_report_counts_updated")
  PrintTable(data)
end


function dotacraft:On_scaleform_file_download_complete(data)
  print("[DOTACRAFT] scaleform_file_download_complete")
  PrintTable(data)
end


function dotacraft:On_item_purchased(data)
  print("[DOTACRAFT] item_purchased")
  PrintTable(data)
end


function dotacraft:On_gc_mismatched_version(data)
  print("[DOTACRAFT] gc_mismatched_version")
  PrintTable(data)
end


function dotacraft:On_demo_skip(data)
  print("[DOTACRAFT] demo_skip")
  PrintTable(data)
end


function dotacraft:On_demo_start(data)
  print("[DOTACRAFT] demo_start")
  PrintTable(data)
end


function dotacraft:On_demo_stop(data)
  print("[DOTACRAFT] demo_stop")
  PrintTable(data)
end


function dotacraft:On_map_shutdown(data)
  print("[DOTACRAFT] map_shutdown")
  PrintTable(data)
end


function dotacraft:On_dota_workshop_fileselected(data)
  print("[DOTACRAFT] dota_workshop_fileselected")
  PrintTable(data)
end


function dotacraft:On_dota_workshop_filecanceled(data)
  print("[DOTACRAFT] dota_workshop_filecanceled")
  PrintTable(data)
end


function dotacraft:On_rich_presence_updated(data)
  print("[DOTACRAFT] rich_presence_updated")
  PrintTable(data)
end


function dotacraft:On_dota_hero_random(data)
  print("[DOTACRAFT] dota_hero_random")
  PrintTable(data)
end


function dotacraft:On_dota_rd_chat_turn(data)
  print("[DOTACRAFT] dota_rd_chat_turn")
  PrintTable(data)
end


function dotacraft:On_dota_favorite_heroes_updated(data)
  print("[DOTACRAFT] dota_favorite_heroes_updated")
  PrintTable(data)
end


function dotacraft:On_profile_closed(data)
  print("[DOTACRAFT] profile_closed")
  PrintTable(data)
end


function dotacraft:On_item_preview_closed(data)
  print("[DOTACRAFT] item_preview_closed")
  PrintTable(data)
end


function dotacraft:On_dashboard_switched_section(data)
  print("[DOTACRAFT] dashboard_switched_section")
  PrintTable(data)
end


function dotacraft:On_dota_tournament_item_event(data)
  print("[DOTACRAFT] dota_tournament_item_event")
  PrintTable(data)
end


function dotacraft:On_dota_hero_swap(data)
  print("[DOTACRAFT] dota_hero_swap")
  PrintTable(data)
end


function dotacraft:On_dota_reset_suggested_items(data)
  print("[DOTACRAFT] dota_reset_suggested_items")
  PrintTable(data)
end


function dotacraft:On_halloween_high_score_received(data)
  print("[DOTACRAFT] halloween_high_score_received")
  PrintTable(data)
end


function dotacraft:On_halloween_phase_end(data)
  print("[DOTACRAFT] halloween_phase_end")
  PrintTable(data)
end


function dotacraft:On_halloween_high_score_request_failed(data)
  print("[DOTACRAFT] halloween_high_score_request_failed")
  PrintTable(data)
end


function dotacraft:On_dota_hud_skin_changed(data)
  print("[DOTACRAFT] dota_hud_skin_changed")
  PrintTable(data)
end


function dotacraft:On_dota_inventory_player_got_item(data)
  print("[DOTACRAFT] dota_inventory_player_got_item")
  PrintTable(data)
end


function dotacraft:On_player_is_experienced(data)
  print("[DOTACRAFT] player_is_experienced")
  PrintTable(data)
end


function dotacraft:On_player_is_notexperienced(data)
  print("[DOTACRAFT] player_is_notexperienced")
  PrintTable(data)
end


function dotacraft:On_dota_tutorial_lesson_start(data)
  print("[DOTACRAFT] dota_tutorial_lesson_start")
  PrintTable(data)
end


function dotacraft:On_map_location_updated(data)
  print("[DOTACRAFT] map_location_updated")
  PrintTable(data)
end


function dotacraft:On_richpresence_custom_updated(data)
  print("[DOTACRAFT] richpresence_custom_updated")
  PrintTable(data)
end


function dotacraft:On_game_end_visible(data)
  print("[DOTACRAFT] game_end_visible")
  PrintTable(data)
end


function dotacraft:On_antiaddiction_update(data)
  print("[DOTACRAFT] antiaddiction_update")
  PrintTable(data)
end


function dotacraft:On_highlight_hud_element(data)
  print("[DOTACRAFT] highlight_hud_element")
  PrintTable(data)
end


function dotacraft:On_hide_highlight_hud_element(data)
  print("[DOTACRAFT] hide_highlight_hud_element")
  PrintTable(data)
end


function dotacraft:On_intro_video_finished(data)
  print("[DOTACRAFT] intro_video_finished")
  PrintTable(data)
end


function dotacraft:On_matchmaking_status_visibility_changed(data)
  print("[DOTACRAFT] matchmaking_status_visibility_changed")
  PrintTable(data)
end


function dotacraft:On_practice_lobby_visibility_changed(data)
  print("[DOTACRAFT] practice_lobby_visibility_changed")
  PrintTable(data)
end


function dotacraft:On_dota_courier_transfer_item(data)
  print("[DOTACRAFT] dota_courier_transfer_item")
  PrintTable(data)
end


function dotacraft:On_full_ui_unlocked(data)
  print("[DOTACRAFT] full_ui_unlocked")
  PrintTable(data)
end


function dotacraft:On_client_connectionless_packet(data)
  print("[DOTACRAFT] client_connectionless_packet")
  PrintTable(data)
end


function dotacraft:On_hero_selector_preview_set(data)
  print("[DOTACRAFT] hero_selector_preview_set")
  PrintTable(data)
end


function dotacraft:On_antiaddiction_toast(data)
  print("[DOTACRAFT] antiaddiction_toast")
  PrintTable(data)
end


function dotacraft:On_hero_picker_shown(data)
  print("[DOTACRAFT] hero_picker_shown")
  PrintTable(data)
end


function dotacraft:On_hero_picker_hidden(data)
  print("[DOTACRAFT] hero_picker_hidden")
  PrintTable(data)
end


function dotacraft:On_dota_local_quickbuy_changed(data)
  print("[DOTACRAFT] dota_local_quickbuy_changed")
  PrintTable(data)
end


function dotacraft:On_show_center_message(data)
  print("[DOTACRAFT] show_center_message")
  PrintTable(data)
end


function dotacraft:On_hud_flip_changed(data)
  print("[DOTACRAFT] hud_flip_changed")
  PrintTable(data)
end


function dotacraft:On_frosty_points_updated(data)
  print("[DOTACRAFT] frosty_points_updated")
  PrintTable(data)
end


function dotacraft:On_defeated(data)
  print("[DOTACRAFT] defeated")
  PrintTable(data)
end


function dotacraft:On_reset_defeated(data)
  print("[DOTACRAFT] reset_defeated")
  PrintTable(data)
end


function dotacraft:On_booster_state_updated(data)
  print("[DOTACRAFT] booster_state_updated")
  PrintTable(data)
end


function dotacraft:On_event_points_updated(data)
  print("[DOTACRAFT] event_points_updated")
  PrintTable(data)
end


function dotacraft:On_local_player_event_points(data)
  print("[DOTACRAFT] local_player_event_points")
  PrintTable(data)
end


function dotacraft:On_custom_game_difficulty(data)
  print("[DOTACRAFT] custom_game_difficulty")
  PrintTable(data)
end


function dotacraft:On_tree_cut(data)
  print("[DOTACRAFT] tree_cut")
  PrintTable(data)
end


function dotacraft:On_ugc_details_arrived(data)
  print("[DOTACRAFT] ugc_details_arrived")
  PrintTable(data)
end


function dotacraft:On_ugc_subscribed(data)
  print("[DOTACRAFT] ugc_subscribed")
  PrintTable(data)
end


function dotacraft:On_ugc_unsubscribed(data)
  print("[DOTACRAFT] ugc_unsubscribed")
  PrintTable(data)
end


function dotacraft:On_prizepool_received(data)
  print("[DOTACRAFT] prizepool_received")
  PrintTable(data)
end


function dotacraft:On_microtransaction_success(data)
  print("[DOTACRAFT] microtransaction_success")
  PrintTable(data)
end


function dotacraft:On_dota_rubick_ability_steal(data)
  print("[DOTACRAFT] dota_rubick_ability_steal")
  PrintTable(data)
end


function dotacraft:On_compendium_event_actions_loaded(data)
  print("[DOTACRAFT] compendium_event_actions_loaded")
  PrintTable(data)
end


function dotacraft:On_compendium_selections_loaded(data)
  print("[DOTACRAFT] compendium_selections_loaded")
  PrintTable(data)
end


function dotacraft:On_compendium_set_selection_failed(data)
  print("[DOTACRAFT] compendium_set_selection_failed")
  PrintTable(data)
end

function dotacraft:On_community_cached_names_updated(data)
  print("[DOTACRAFT] community_cached_names_updated")
  PrintTable(data)
end

function dotacraft:On_dota_team_kill_credit(data)
  print("[DOTACRAFT] dota_team_kill_credit")
  PrintTable(data)
end
