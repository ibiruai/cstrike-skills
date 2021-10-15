#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>

#define EXTRA_LIFE_GIVES_WEAPONS
// #define SKILLS_MOTD
// #define BOTS_HAVE_SKILLS
new const Float:GRAVITY = 0.5
new const Float:AMMO_TIME = 0.5
new const AMMO_TO_ADD = 2
new const EXTRA_HP = 25
new const Float:LIFE_STEAL = 0.2
new const Float:EXTRA_LIFE_TIME = 5.0
new const GRENADE_TRAPS_LIMIT = 8
new const REPELING_GRENADES_LIMIT = 4
new const HEALING_GRENADES_LIMIT = 4
new const REPELING_GRENADE_DISTANCE = 250
new const HEALING_GRENADE_DISTANCE = 350
new const Float:HEALING_GRENADE_TIME = 0.5
new const Float:REPELING_GRENADE_TIME = 0.05
new const Float:HEALING_GRENADE_LIFE = 25.0
new const Float:REPELING_GRENADE_LIFE = 15.0
new const GRENADE_HEAL = 30
new const GRENADE_OVERHEAL = 50
new const REPEL_COLOR[3] = {255, 100, 255}
new const HEAL_COLOR[3] = {100, 255, 100}
new const Float:GHOST_TIME = 5.0
new const Float:GHOST_COOLDOWN = 15.0
new const Float:SPIDER_WEB_SPEED = 400.0
new const Float:HOOK_SPEED = 500.0
new const Float:HARPOON_SPEED = 1000.0
new const Float:HOOK_CHARGING_TIME = 4.0
new const HOOK_CHARGES = 5
new const Float:SPRINT_TIME = 6.0
new const Float:SPRINT_COOLDOWN = 12.0
new const Float:SPRINT_SPEED = 550.0
new const Float:LEAP_COOLDOWN = 10.0
new const Float:DISARM_COOLDOWN = 6.0
new const Float:FREE_GRENADES_COOLDOWN = 6.0
new const Float:ELECTROSHOCK_COOLDOWN = 8.0
new const Float:DISORIENT_COOLDOWNS_TIME = 2.0

new const names[24][25] = {"SKILLS_ANTIGRAVITY", "SKILLS_SILENT_FOOTSTEPS", "SKILLS_WEALTHINESS", "SKILLS_SIDE_JUMP", "SKILLS_AMMO_RESUPPLY", "SKILLS_GRENADE_TRAPS", "SKILLS_REPELING_GRENADES", "SKILLS_EXTRA_LIFE", "SKILLS_EXTRA_HP", "SKILLS_FALL_PROTECTION", "SKILLS_HEALING_GRENADES", "SKILLS_LIFE_STEAL", "SKILLS_TRIPLE_JUMPS", "SKILLS_GHOST", "SKILLS_HARPOON", "SKILLS_HOOK", "SKILLS_PARACHUTE", "SKILLS_SPIDER_WEB", "SKILLS_SPRINT", "SKILLS_FREE_GRENADES", "SKILLS_DISARM", "SKILLS_LEAP", "SKILLS_ELECTROSHOCK", "SKILLS_FLASHLIGHT"}
new const passive_count = 13
new const active1_count = 6

enum (+= 1000) {
    EXTRA_LIFE_TASK = 1000, PRESS_E_TASK, END_E_TASK, RELEASE_E_TASK, INFO_TASK,
    CAST_F_TASK, HOOK_TASK, HARPOON_REELIN_TASK, HARPOON_ESCAPE_TASK,
    DISORIENTED_TASK, VELOCITY_TASK, SLAY_STUCK_TASK, BOT_TASK
}

new bool:has_antigravity[33]
new bool:has_triple_jumps[33]
new triple_jumps_jumps_left[33]
new bool:has_silent_footsteps[33]
new bool:has_wealthiness[33]
new bool:has_ammo_resupply[33]
new bool:has_extra_hp[33]
new bool:has_life_steal[33]
new bool:has_extra_life[33]
new bool:used_extra_life[33]
new extra_life_origin[33][3]
new extra_life_old_team[33]
new Float:extra_life_countdown[33]
new bool:has_grenade_traps[33]
new grenade_traps_count[33]
new bool:has_repeling_grenades[33]
new repeling_grenades_count[33]
new disoriented_by[33]
new bool:has_healing_grenades[33]
new healing_grenades_count[33]
new bool:has_fall_protection[33]
new bool:has_side_jump[33]

new bool:has_harpoon[33]
new hit_with_harpoon[33]
new bool:has_parachute[33]
new bool:has_spider_web[33]
new hooked[33]
new hook_location[33][3]
new hook_length[33]
new Float:hook_created[33]
new bool:has_ghost[33]
new bool:ghost_stuck[33]
new bool:has_hook[33]
new bool:has_sprint[33]

new bool:has_leap[33]
new bool:has_disarm[33]
new bool:disarm_falling[33]
new disarm_origin_z[33]
new bool:has_free_grenades[33]
new bool:has_flashlight[33]
new bool:has_electroshock[33]

new skills_count[33]
new bool:menu_shown[33]
new menu_page[33]
new skills_selected[33][5]
new Float:e_cooldown[33]
new Float:e_in_progress[33]
new e_max_charges[33]
new e_charges[33]
new Float:e_charging_time[33]
new Float:e_charging[33]
new Float:f_cooldown[33]
new f_target[33]
new f_target_name[33][32]
new f_searching[33]
new bool:asked_for_reset[33]
new bool:round_started
new msg_sync, gren_tail, sprite_line, sprite_lightning
//-----------------------------------------------------------------------------
public plugin_init() {
    register_plugin("Skills Mod", "0.1.13", "Various authors")
    register_dictionary("skills_mod.txt")
    RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "forward_maxspeed")
    RegisterHam(Ham_Killed, "player", "player_killed", 1)
    RegisterHam(Ham_Spawn, "player", "player_spawned", 1)
    RegisterHam(Ham_TakeDamage, "player", "player_damaged")
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_flashbang", "flashbang_attack")
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_hegrenade", "hegrenade_attack")
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_smokegrenade", "smokegrenade_attack")
    register_clcmd("say /reset", "say_reset")
    #if defined SKILLS_MOTD
    register_clcmd("say /skills", "say_skills")
    #endif
    register_event("HLTV", "new_round_event", "a", "1=0", "2=0")
    register_forward(FM_EmitSound, "forward_emitsound")
    register_forward(FM_SetModel, "forward_setmodel")
    register_forward(FM_TraceLine, "forward_traceline", 1)
    register_logevent("round_start", 2, "1=Round_Start")
    register_think("grenade", "think_grenade")
    register_think("grenade_totem", "grenade_totem_think")
    register_think("think_bot", "think_bot")
    set_task(0.1, "flashlight_esp", _, _, _, "b")
    set_task(AMMO_TIME, "ammo_resupply", _, _, _, "b")
    _create_ThinkBot()
    msg_sync = CreateHudSyncObj()
    server_cmd("sv_maxspeed 900")
}
//-----------------------------------------------------------------------------
public plugin_precache() {
    gren_tail = precache_model("sprites/zbeam5.spr")
    sprite_lightning = precache_model("sprites/lgtning.spr")
    sprite_line = precache_model("sprites/zbeam4.spr")
    precache_sound("bullchicken/bc_bite2.wav")
    precache_sound("player/headshot3.wav")
    precache_sound("weapons/xbow_fire1.wav")
    precache_sound("weapons/xbow_hitbod1.wav")
    precache_sound("turret/tu_ping.wav")
    precache_sound("weapons/gauss2.wav")
}
//-----------------------------------------------------------------------------
public new_round_event() {
    new players[32], players_count, id
    get_players(players, players_count)
    for (new i = 0; i < players_count; i++) {
        id = players[i]
        if (is_user_connected(id)) {
            if (asked_for_reset[id])
                reset(id)
            if ((cs_get_user_team(id) == CS_TEAM_CT || cs_get_user_team(id) == CS_TEAM_T) && skills_count[id] < 5) {
                #if defined BOTS_HAVE_SKILLS
                if (is_user_bot(id))
                    give_skills_to_bot(id)
                else
                #endif
                    skills_menu(id)
            }
        }
        grenade_traps_count[id] = 0
        repeling_grenades_count[id] = 0
        healing_grenades_count[id] = 0
        used_extra_life[id] = false
        disarm_falling[id] = false
        f_target[id] = 0
    }
    new i_ent = find_ent_by_class(-1, "grenade_totem")
    while (i_ent > 0) {
        remove_entity(i_ent)
        i_ent = find_ent_by_class(i_ent, "grenade_totem")
    }
    round_started = false
}
//-----------------------------------------------------------------------------
public round_start()
    round_started = true
//-----------------------------------------------------------------------------
public say_reset(id) {
    asked_for_reset[id] = true
    if (is_user_alive(id) || extra_life_countdown[id])
        client_print(id, print_chat, "%L", id, "SKILLS_RESET_MESSAGE")
    else
        reset(id, true)
    return PLUGIN_HANDLED
}

#if defined SKILLS_MOTD
public say_skills(id) {
    new string[2000] = "<html><head><meta charset='UTF-8'><style>body{background:#000;margin:8px;color: #FFB000;font: normal 16px/20px Verdana, Tahoma, sans-serif;}ct{color:#A4CBF2}t{color:#E04D4D}</style></head><body>"
    static players[32], players_count, pid, player_name[32]
    get_players(players, players_count, "e", "TERRORIST")
    for (new i = 0; i < players_count; i++) {
        pid = players[i]
        get_user_name(pid, player_name, 32)
        formatex(string, 2000, "%s<t>%s</t>: ", string, player_name)
        for (new j = 0; j < skills_count[pid] - 1; j++)
            formatex(string, 2000, "%s%L, ", string, id, names[skills_selected[pid][j]])
        if (skills_count[pid] > 0)
            formatex(string, 2000, "%s%L</br>", string, id, names[skills_selected[pid][skills_count[pid] - 1]])
        else
            formatex(string, 2000, "%s</br>", string)
    }
    get_players(players, players_count, "e", "CT")
    for (new i = 0; i < players_count; i++) {
        pid = players[i]
        get_user_name(pid, player_name, 32)
        formatex(string, 2000, "%s<ct>%s</ct>: ", string, player_name)
        for (new j = 0; j < skills_count[pid] - 1; j++)
            formatex(string, 2000, "%s%L, ", string, id, names[skills_selected[pid][j]])
        if (skills_count[pid] > 0)
            formatex(string, 2000, "%s%L</br>", string, id, names[skills_selected[pid][skills_count[pid] - 1]])
        else
            formatex(string, 2000, "%s</br>", string)
    }
    formatex(string, 2000, "%s</body></html>", string)
    show_motd(id, string)  // не помещается
    return PLUGIN_HANDLED
}
#endif
//-----------------------------------------------------------------------------
reset(id, menu = false) {
    has_antigravity[id] = false
    has_triple_jumps[id] = false
    has_silent_footsteps[id] = false
    has_wealthiness[id] = false
    has_ammo_resupply[id] = false
    has_extra_hp[id] = false
    has_life_steal[id] = false
    has_extra_life[id] = false
    has_grenade_traps[id] = false
    has_repeling_grenades[id] = false
    has_healing_grenades[id] = false
    has_fall_protection[id] = false
    has_side_jump[id] = false
    has_harpoon[id] = false
    has_parachute[id] = false
    has_spider_web[id] = false
    has_ghost[id] = false
    has_sprint[id] = false
    has_hook[id] = false
    has_leap[id] = false
    has_disarm[id] = false
    has_free_grenades[id] = false
    has_flashlight[id] = false
    has_electroshock[id] = false
    menu_page[id] = 0
    skills_count[id] = 0
    asked_for_reset[id] = false
    if (is_user_connected(id)) {
        set_user_footsteps(id, 0)
        if (menu)
            skills_menu(id)
    }
}
//-----------------------------------------------------------------------------
public client_putinserver(id) {
    reset(id)
    grenade_traps_count[id] = 0
    repeling_grenades_count[id] = 0
    healing_grenades_count[id] = 0
    ghost_stuck[id] = false
    menu_shown[id] = false
}
//-----------------------------------------------------------------------------
public client_disconnected(id) {
    remove_task(PRESS_E_TASK + id)
    remove_task(END_E_TASK + id)
    remove_task(HOOK_TASK + id)
    #if defined BOTS_HAVE_SKILLS
    remove_task(BOT_TASK + id)
    #endif
    harpoon_off(id)
    static players[32], players_count, pid
    get_players(players, players_count, "ah")
    for (new i = 0; i < players_count; i++) {
        pid = players[i]
        if (f_target[pid] == id)
            f_target[pid] = 0
    }
}
//-----------------------------------------------------------------------------
public player_spawned(id) {
    if (!is_user_connected(id))
        return
    if (has_extra_hp[id])
        set_user_health(id, get_user_health(id) + EXTRA_HP)
    give_buffs(id)
    extra_life_countdown[id] = 0.0
    e_in_progress[id] = 0.0
    e_cooldown[id] = 0.0
    f_cooldown[id] = 0.0
    f_searching[id] = false
    e_charges[id] = e_max_charges[id]
    if (has_grenade_traps[id])
        give_item(id, "weapon_hegrenade")
    if (has_repeling_grenades[id]) {
        give_item(id, "weapon_flashbang")
        cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
    }
    if (has_healing_grenades[id])
        give_item(id, "weapon_smokegrenade")
    if (hooked[id])
        hook_off(id)
    if (hit_with_harpoon[id])
        harpoon_off(id)
    if (menu_shown[id] == false)
        skills_menu(id)
}
//-----------------------------------------------------------------------------
public give_buffs(id) {
    if (!is_user_alive(id))
        return
    if (has_antigravity[id])
        set_user_gravity(id, GRAVITY)
    if (has_silent_footsteps[id])
        set_user_footsteps(id, 1)
    if (has_wealthiness[id])
        cs_set_user_money(id, 16000)
}
//-----------------------------------------------------------------------------
public player_killed(victim, attacker) {
    remove_task(PRESS_E_TASK + victim)
    remove_task(END_E_TASK + victim)
    hook_off(victim)
    harpoon_off(victim)
    abort_ghost(victim)
    f_searching[victim] = false
    if (is_user_connected(victim) && has_extra_life[victim] && !used_extra_life[victim]) {
        get_user_origin(victim, extra_life_origin[victim])
        extra_life_origin[victim][2] += (get_user_button(victim) & IN_DUCK) ? 18 : 8
        extra_life_old_team[victim] = get_user_team(victim)
        used_extra_life[victim] = true
        set_task(0.6, "set_extra_life_countdown", victim + EXTRA_LIFE_TASK)
    } else {
        f_target[victim] = 0
        if (asked_for_reset[victim])
            reset(victim, true)
    }
    static players[32], players_count, id
    get_players(players, players_count, "ah")
    for (new i = 0; i < players_count; i++) {
        id = players[i]
        if (f_target[id] == victim)
            f_target[id] = 0
    }
}
//-----------------------------------------------------------------------------
public player_damaged(this, inflictor, attacker, Float:damage, damagebits) {
    new bool:is_disorient_damage = false
    if (damagebits & DMG_FALL && task_exists(DISORIENTED_TASK + this)) {
        attacker = disoriented_by[this]
        is_disorient_damage = true
    }
    if (is_user_alive(attacker) && has_life_steal[attacker] && (is_disorient_damage || cs_get_user_team(this) != cs_get_user_team(attacker)))
        set_user_health(attacker, min(get_user_health(attacker) + floatround(damage * LIFE_STEAL), has_extra_hp[attacker] ? 100 + EXTRA_HP : 100))
    if (is_user_alive(this) && damagebits & DMG_FALL && task_exists(DISORIENTED_TASK + this) && is_user_connected(disoriented_by[this]) && damage > get_user_health(this)) {
        ExecuteHam(Ham_Killed, this, disoriented_by[this], false)
        player_killed(this, disoriented_by[this])
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}
//-----------------------------------------------------------------------------
public client_PreThink(id) {
    new button = pev(id, pev_button)
    if (!is_user_alive(id) && extra_life_countdown[id] && (button & IN_FORWARD || button & IN_MOVELEFT || button & IN_MOVERIGHT || button & IN_BACK))
        extra_life_respawn(id)
    if (!is_user_alive(id) || !round_started)
        return
    new old_button = pev(id, pev_oldbuttons)
    new bool:is_falling = !(pev(id, pev_flags) & FL_ONGROUND)
    if (button & IN_USE && !(old_button & IN_USE) && (e_cooldown[id] == 0 || e_in_progress[id] && has_ghost[id]) && !task_exists(PRESS_E_TASK + id)) {
        set_task(0.0, "pressed_e", PRESS_E_TASK + id)
    } else if (old_button & IN_USE && !(button & IN_USE)) {
        set_task(0.0, "released_e", RELEASE_E_TASK + id)
    } else if (get_user_noclip(id) && get_user_weapon(id) == CSW_C4 && button & IN_ATTACK)
        set_pev(id, pev_button, button & ~IN_ATTACK)

    // Side jump forums.alliedmods.net/showthread.php?t=41447
    if (has_side_jump[id] && !is_falling && button & IN_JUMP && (button & IN_MOVERIGHT || button & IN_MOVELEFT) && !(button & IN_FORWARD) && !(button & IN_BACK)) {
        new Float:limit = has_sprint[id] && e_in_progress[id] ? SPRINT_SPEED * 2 : 500.0
        new Float:velocity[3]
        entity_get_vector(id, EV_VEC_velocity, velocity)
        velocity[0] = floatclamp(velocity[0] * 2, -limit, limit)
        velocity[1] = floatclamp(velocity[1] * 2, -limit, limit)
        velocity[2] = 300.0
        entity_set_vector(id, EV_VEC_velocity, velocity)
    }

    // Triple jumps forums.alliedmods.net/showthread.php?t=32041
    if (has_triple_jumps[id]) {
        if (!is_falling)
            triple_jumps_jumps_left[id] = 2
        else if (button & IN_JUMP && !(old_button & IN_JUMP) && triple_jumps_jumps_left[id] > 0) {
            static Float:velocity[3]
            entity_get_vector(id, EV_VEC_velocity, velocity)
            velocity[2] = random_float(265.0, 285.0)
            entity_set_vector(id, EV_VEC_velocity, velocity)
            triple_jumps_jumps_left[id]--
        }
    }

    // Disarming stomp diablo2.sma
    if (has_disarm[id] && disarm_origin_z[id] != 0) {
        disarm_falling[id] = is_falling
        if (!disarm_falling[id])
            disarm_stomp(id)
    }
}

public client_PostThink(id) {
    if (has_fall_protection[id] || disarm_falling[id])
        set_pev(id, pev_watertype, -3)
}

public pressed_e(task_id) {
    new id = task_id - PRESS_E_TASK
    if (!is_user_alive(id))
        return
    if (has_ghost[id]) {
        if (e_in_progress[id] == 0.0 && e_cooldown[id] == 0.0)
            cast_ghost(id)
        else if (!is_stuck(id))
            abort_ghost(id)
    } else if (has_parachute[id]) {
        cast_parachute(PRESS_E_TASK + id)
    } else if (has_spider_web[id] && hooked[id] == 0) {
        killbeam(id)
        hooked[id] = 1
        cast_hook(id)
    } else if (has_hook[id] && hooked[id] == 0 && e_charges[id] > 0) {
        killbeam(id)
        hooked[id] = 2
        cast_hook(id)
    } else if (has_harpoon[id]) {
        harpoon_off(id)
        cast_harpoon(id)
    } else if (has_sprint[id]) {
        cast_sprint(id)
    }
}

public released_e(task_id) {
    new id = task_id - RELEASE_E_TASK
    if (has_parachute[id])
        remove_task(PRESS_E_TASK + id)
    else if (hooked[id])
        hook_off(id)
    else if (has_harpoon[id])
        harpoon_off(id)
}

public client_impulse(id, impulse) {
    if (impulse != 100)
        return PLUGIN_CONTINUE
    if (!round_started)
        return PLUGIN_HANDLED
    if (is_user_alive(id) && f_cooldown[id] == 0) {
        if (has_flashlight[id])
            return PLUGIN_CONTINUE
        if (has_leap[id]) {
            if (get_user_noclip(id))
                abort_ghost(id)
            if (hooked[id] == 2) {
                client_cmd(id, "-use")
                set_task(0.2, "cast_leap", CAST_F_TASK + id)
            }
            cast_leap(CAST_F_TASK + id)
        } else if (has_disarm[id]) {
            if (get_user_noclip(id))
                abort_ghost(id)
            if (hooked[id] == 2)
                client_cmd(id, "-use")
            new Float:velocity[3]
            get_user_velocity(id, velocity)
            velocity[2] = 450.0
            fm_set_user_velocity(id, velocity)
            set_task(0.3, "cast_disarm", CAST_F_TASK + id)
        } else if (has_free_grenades[id]) {
            give_item(id, "weapon_hegrenade")
            give_item(id, "weapon_flashbang")
            give_item(id, "weapon_smokegrenade")
            cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
            set_f_cooldown(id, FREE_GRENADES_COOLDOWN)
        } else if (has_electroshock[id]) {
            toggle_f_searching(id)
            if (f_searching[id])
                electroshock_search(CAST_F_TASK + id)
            else
                remove_task(CAST_F_TASK + id)
        }
    }
    return PLUGIN_HANDLED
}
//-----------------------------------------------------------------------------
public cast_disarm(task_id) {
    new id = task_id - CAST_F_TASK
    if (!is_user_alive(id))
        return
    new origin[3]
    get_user_origin(id, origin)
    if (origin[2] == 0)
        disarm_origin_z[id] = 1
    else
        disarm_origin_z[id] = origin[2]
    set_user_gravity(id, 5.0)
    disarm_falling[id] = true
    set_f_cooldown(id, DISARM_COOLDOWN)
}
//-----------------------------------------------------------------------------
public cast_leap(task_id) {
    new id = task_id - CAST_F_TASK
    if (!is_user_alive(id))
        return
    new Float:fl_iNewVelocity[3]
    VelocityByAim(id, 2000, fl_iNewVelocity)
    entity_set_vector(id, EV_VEC_velocity, fl_iNewVelocity)
    set_f_cooldown(id, LEAP_COOLDOWN)
}
//-----------------------------------------------------------------------------
// forums.alliedmods.net/showpost.php?p=2407600&postcount=5
public forward_emitsound(id, iChannel, szSound[], Float:fVol, Float:fAttn, iFlags, iPitch) {
    if (equal(szSound, "common/wpn_select.wav"))
        remove_task(PRESS_E_TASK + id)
    if (equal(szSound, "common/wpn_denyselect.wav") && round_started && skills_count[id] > 3 && (!e_cooldown[id] || has_ghost[id] && e_in_progress[id]) && (!has_hook[id] || e_charges[id])) {
        if (task_exists(PRESS_E_TASK + id))
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}
//-----------------------------------------------------------------------------
public cast_ghost(id) {
    set_user_noclip(id, 1)
    set_e_cooldown(id, GHOST_COOLDOWN, GHOST_TIME)
    set_task(GHOST_TIME, "end_ghost", END_E_TASK + id)
}

public abort_ghost(id) {
    remove_task(END_E_TASK + id)
    end_ghost(END_E_TASK + id)
    e_cooldown[id] -= e_in_progress[id]
    e_in_progress[id] = 0.0
}

public end_ghost(task_id) {
    new id = task_id - END_E_TASK
    if (!is_user_connected(id))
        return
    set_user_noclip(id, 0)

    // kill a stuck player
    // superheromod.inc forums.alliedmods.net/showthread.php?t=76081
    if (is_stuck(id)) {
        ghost_stuck[id] = true
        user_kill(id)
    }
}
//-----------------------------------------------------------------------------
// Turbo forums.alliedmods.net/showthread.php?t=41447
public cast_sprint(id) {
    entity_set_float(id, EV_FL_maxspeed, SPRINT_SPEED)
    set_e_cooldown(id, SPRINT_COOLDOWN, SPRINT_TIME)
    set_task(SPRINT_TIME + 0.1, "end_sprint", END_E_TASK + id)
}

public forward_maxspeed(id) {
    if (has_sprint[id] && e_in_progress[id])
        return HAM_SUPERCEDE
    return HAM_IGNORED
}

public end_sprint(task_id) {
    new id = task_id - END_E_TASK
    if (is_user_alive(id))
        ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id)
}
//-----------------------------------------------------------------------------
// forums.alliedmods.net/showpost.php?p=2376177&postcount=6
public cast_parachute(task_id) {
    new id = task_id - PRESS_E_TASK
    if (!(get_entity_flags(id) & FL_ONGROUND)) {
        new Float:velocity[3]
        entity_get_vector(id, EV_VEC_velocity, velocity)
        velocity[2] = 0.0
        entity_set_vector(id, EV_VEC_velocity, velocity)
        set_task(0.05, "cast_parachute", task_id)
    }
}
//-----------------------------------------------------------------------------
// forums.alliedmods.net/showthread.php?t=30270
public extra_life_respawn(id) {
    if (extra_life_old_team[id] != get_user_team(id))
        return
    extra_life_countdown[id] = 0.0
    ExecuteHamB(Ham_CS_RoundRespawn, id)
    #if defined EXTRA_LIFE_GIVES_WEAPONS
    static const weapons[4][14] = {"weapon_m3", "weapon_xm1014", "weapon_p90", "weapon_mac10"}
    give_item(id, weapons[random(4)])
    #endif
    set_user_origin(id, extra_life_origin[id])
    if (has_ghost[id] && ghost_stuck[id]) {
        cast_ghost(id)
        ghost_stuck[id] = false
    } else if (is_stuck(id))
        unstuck(id)
}

public is_stuck(id) {
    new Float:origin[3], hullsize
    pev(id, pev_origin, origin)
    hullsize = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
    engfunc(EngFunc_TraceHull, origin, origin, 0, hullsize, id, 0)
    return get_tr2(0, TraceResult:TR_StartSolid) || get_tr2(0, TraceResult:TR_AllSolid) || !get_tr2(0, TraceResult:TR_InOpen)
}

public unstuck(id) {
    new hullsize = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
    new Float:origin[3], Float:new_origin[3]
    pev(id, pev_origin, origin)
    for (new distance = 32; distance <= 160; distance += 32) {
        for (new i = 0; i < 128; i++) {
            new_origin[0] = random_float(origin[0] - distance, origin[0] + distance)
            new_origin[1] = random_float(origin[1] - distance, origin[1] + distance)
            new_origin[2] = random_float(origin[2] - distance, origin[2] + distance)
            if (fm_trace_hull(new_origin, hullsize, id) == 0) {
                fm_entity_set_origin(id, new_origin)
                return
            }
        }
    }
    set_task(0.4, "slay_stuck", SLAY_STUCK_TASK + id)
}

public slay_stuck(task_id) {
    new id = task_id - SLAY_STUCK_TASK
    if (is_user_alive(id))
        user_kill(id)
}
//-----------------------------------------------------------------------------
// sh_punisherv2.sma forums.alliedmods.net/showthread.php?t=131398
public ammo_resupply() {
    static players[32], players_count, id
    get_players(players, players_count, "ah")
    for (new i = 0; i < players_count; i++) {
        id = players[i]
        if (has_ammo_resupply[id]) {
            new ca
            switch (get_user_weapon(id)) {
                case CSW_P228: ca = 13
                case CSW_SCOUT: ca = 10
                case CSW_HEGRENADE: ca = 1
                case CSW_XM1014: ca = 7
                case CSW_C4: ca = 1
                case CSW_MAC10: ca = 30
                case CSW_AUG: ca = 30
                case CSW_SMOKEGRENADE: ca = 1
                case CSW_ELITE: ca = 15
                case CSW_FIVESEVEN: ca = 20
                case CSW_UMP45: ca = 25
                case CSW_SG550: ca = 30
                case CSW_GALI: ca = 35
                case CSW_FAMAS: ca = 25
                case CSW_USP: ca = 12
                case CSW_GLOCK18: ca = 20
                case CSW_AWP: ca = 10
                case CSW_MP5NAVY: ca = 30
                case CSW_M249: ca = 100
                case CSW_M3: ca = 8
                case CSW_M4A1: ca = 30
                case CSW_TMP: ca = 30
                case CSW_G3SG1: ca = 20
                case CSW_FLASHBANG: ca = 2
                case CSW_DEAGLE: ca = 7
                case CSW_SG552: ca = 30
                case CSW_AK47: ca = 30
                case CSW_P90: ca = 50
            }
            new weaponEnt = get_pdata_cbase(id, 373)
            if (weaponEnt > 0) {
                new current_ammo = cs_get_weapon_ammo(weaponEnt)
                new new_ammo = min(current_ammo + AMMO_TO_ADD, ca)
                cs_set_weapon_ammo(get_pdata_cbase(id, 373), new_ammo)
            }
        }
    }
}
//-----------------------------------------------------------------------------
public disarm_stomp(id) {
    set_user_gravity(id, 1.0)
    give_buffs(id)
    new origin[3]
    get_user_origin(id, origin)
    if (disarm_origin_z[id] - origin[2] > 85) {
        message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0, 0, 0} , id)
        write_short(1<<14)
        write_short(1<<12)
        write_short(1<<14)
        message_end()
        new entlist[513]
        new numfound = find_sphere_class(id, "player", 250.0, entlist, 512)
        for (new i = 0; i < numfound; i++) {
            new pid = entlist[i]
            if (pid == id || !is_user_alive(pid) || !(pev(pid, pev_flags) & FL_ONGROUND))
                continue
            new Float:id_origin[3]
            new Float:pid_origin[3]
            new Float:delta_vec[3]
            pev(id, pev_origin, id_origin)
            pev(pid, pev_origin, pid_origin)
            new weapon, clip, ammo, weapon_name[22]
            weapon = get_user_weapon(pid, clip, ammo)
            if (weapon != CSW_KNIFE && weapon != CSW_HEGRENADE && weapon != CSW_FLASHBANG && weapon != CSW_SMOKEGRENADE) {
                get_weaponname(weapon, weapon_name, charsmax(weapon_name))
                engclient_cmd(pid, "drop", weapon_name)
            }
            delta_vec[0] = (pid_origin[0] - id_origin[0]) + 10
            delta_vec[1] = (pid_origin[1] - id_origin[1]) + 10
            delta_vec[2] = (pid_origin[2] - id_origin[2]) + clamp(disarm_origin_z[id] - origin[2], 200, 1000)
            set_pev(pid, pev_velocity, delta_vec)
            message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0, 0, 0} , pid)
            write_short(1<<14)
            write_short(1<<12)
            write_short(1<<14)
            message_end()
        }
    }
    disarm_origin_z[id] = 0
    return PLUGIN_CONTINUE
}
//-----------------------------------------------------------------------------
public set_e_cooldown(id, Float:cooldown, Float:in_progress) {
    e_cooldown[id] = cooldown
    e_in_progress[id] = in_progress
    if (!task_exists(id + INFO_TASK))
        display_cooldown(id + INFO_TASK)
}

public set_e_charging(id, Float:charging_time) {
    if (e_charges[id] == e_max_charges[id]) {
        e_charging_time[id] = charging_time
        e_charging[id] = charging_time
    }
    e_charges[id]--
    if (!task_exists(id + INFO_TASK))
        display_cooldown(id + INFO_TASK)
}

public set_extra_life_countdown(task_id) {
    new id = task_id - EXTRA_LIFE_TASK
    if (extra_life_old_team[id] != get_user_team(id))
        return
    extra_life_countdown[id] = EXTRA_LIFE_TIME
    remove_task(id + INFO_TASK)
    if (!task_exists(id + INFO_TASK))
        display_cooldown(id + INFO_TASK)
}

public set_f_cooldown(id, Float:cooldown) {
    f_cooldown[id] = cooldown
    if (!task_exists(id + INFO_TASK))
        display_cooldown(id + INFO_TASK)
}

public set_f_target(id, target) {
    f_target[id] = target
    get_user_name(target, f_target_name[id], 32)
    if (!task_exists(id + INFO_TASK))
        display_cooldown(id + INFO_TASK)
}

public toggle_f_searching(id) {
    f_searching[id] = !f_searching[id] ? 1 : 0
    if (!task_exists(id + INFO_TASK))
        display_cooldown(id + INFO_TASK)
}

public display_cooldown(task_id) {
    new id = task_id - INFO_TASK
    new string[100] = ""
    if (extra_life_countdown[id] && !is_user_alive(id)) {
        if (extra_life_countdown[id] > 0.5)
            formatex(string, 100, "WASD: %L - %ds", id, "SKILLS_EXTRA_LIFE", floatround(extra_life_countdown[id] - 0.5))
        else if (asked_for_reset[id])
            reset(id, true)
    } else {
        if (e_in_progress[id] > 0)
            formatex(string, 100, "...%ds...", floatround(e_in_progress[id]))
        else if (e_cooldown[id] > 0)
            formatex(string, 100, "E: %ds", floatround(e_cooldown[id]))
        else if (e_charges[id] != e_max_charges[id])
            formatex(string, 100, "E: %d/%d (%ds)", e_charges[id], e_max_charges[id], floatround(e_charging[id]))
        if (f_cooldown[id] > 0)
            formatex(string, 100, "%s^nF: %ds", string, floatround(f_cooldown[id]))
        else if (f_target[id] != 0)
            formatex(string, 100, "%s^nF: %s", string, f_target_name[id])
        else if (f_searching[id]) {
            static const progress_bar[7][8] = {"*------", "-*-----", "--*----", "---*---", "----*--", "-----*-", "------*"}
            formatex(string, 100, "%s^nF: %s", string, progress_bar[f_searching[id] - 1])
        }
    }
    if (task_exists(task_id)) {
        extra_life_countdown[id] = floatmax(0.0, extra_life_countdown[id] - 0.5)
        e_in_progress[id] = floatmax(0.0, e_in_progress[id] - 0.5)
        e_cooldown[id] = floatmax(0.0, e_cooldown[id] - 0.5)
        f_cooldown[id] = floatmax(0.0, f_cooldown[id] - 0.5)
        e_charging[id] = floatmax(0.0, e_charging[id] - 0.5)
        if (e_charges[id] != e_max_charges[id] && e_charging[id] == 0.0)
            if (++e_charges[id] != e_max_charges[id])
                e_charging[id] = e_charging_time[id]
        if (f_searching[id])
            f_searching[id] = f_searching[id] == 7 ? 1 : f_searching[id] + 1
    }
    if (e_charges[id] == e_max_charges[id] && e_cooldown[id] == 0 && f_cooldown[id] == 0 && !f_searching[id] && extra_life_countdown[id] == 0)
        remove_task(task_id)
    set_hudmessage(0, 100, 200, 0.05, 0.55, _, _, 0.5, _, _, 3)
    ShowSyncHudMsg(id, msg_sync, string)
    set_task(0.5, "display_cooldown", task_id)
}
//-----------------------------------------------------------------------------
// Grenade Trap forums.alliedmods.net/showthread.php?t=41781
public _create_ThinkBot() {
    new think_bot = create_entity("info_target")
    if (!is_valid_ent(think_bot))
        log_amx("For some reason, the universe imploded, reload your server")
    else  {
        entity_set_string(think_bot, EV_SZ_classname, "think_bot")
        entity_set_float(think_bot, EV_FL_nextthink, halflife_time() + 1.0)
    }
}

public grenade_throw(id, ent, wID) {
    if (has_healing_grenades[id] && wID == CSW_SMOKEGRENADE || has_repeling_grenades[id] && wID == CSW_FLASHBANG) {
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(22)
        write_short(ent)
        write_short(gren_tail)
        write_byte(10)
        write_byte(10)
        if (wID == CSW_SMOKEGRENADE) {
            write_byte(HEAL_COLOR[0])
            write_byte(HEAL_COLOR[1])
            write_byte(HEAL_COLOR[2])
        } else {
            write_byte(REPEL_COLOR[0])
            write_byte(REPEL_COLOR[1])
            write_byte(REPEL_COLOR[2])
        }
        write_byte(255)
        message_end()
    }
    if (!has_grenade_traps[id] || wID != CSW_HEGRENADE || !is_valid_ent(ent))
        return PLUGIN_CONTINUE
    new Float:fVelocity[3]
    VelocityByAim(id, 90, fVelocity)
    entity_set_vector(ent, EV_VEC_velocity, fVelocity)
    entity_set_int(ent, EV_INT_iuser4, 0)
    entity_set_int(ent, EV_INT_iuser2, 0)
    entity_set_int(ent, EV_INT_iuser1, 0)
    entity_set_int(ent, EV_INT_iuser3, get_user_team(id))
    grenade_traps_count[id]++
    new param[1]
    param[0] = ent
    set_task(1.2, "activate_trap", 0, param, 1)
    return PLUGIN_CONTINUE
}

public activate_trap(param[]) {
    new ent = param[0]
    if (!is_valid_ent(ent))
        return PLUGIN_CONTINUE
    entity_set_int(ent, EV_INT_iuser4, 1)
    entity_set_int(ent, EV_INT_iuser2, 1)
    new Float:fOrigin[3]
    entity_get_vector(ent, EV_VEC_origin, fOrigin)
    entity_set_vector(ent, EV_VEC_origin, fOrigin)
    return PLUGIN_CONTINUE
}

public think_grenade(ent) {
    new entModel[33]
    entity_get_string(ent, EV_SZ_model, entModel, 32)
    if (!is_valid_ent(ent) || equal(entModel, "models/w_c4.mdl"))
        return PLUGIN_CONTINUE
    if (entity_get_int(ent, EV_INT_iuser4))
        return PLUGIN_HANDLED
    return PLUGIN_CONTINUE
}

public think_bot(bot) {
    new ent = -1
    while((ent = find_ent_by_class(ent, "grenade"))) {
        new entModel[33]
        entity_get_string(ent, EV_SZ_model, entModel, 32)
        if (equal(entModel, "models/w_c4.mdl"))
            continue
        if (!entity_get_int(ent, EV_INT_iuser2))
            continue
        new Players[32], iNum
        get_players(Players, iNum, "a")
        for (new i = 0; i < iNum; ++i) {
            new id = Players[i]
            if (entity_get_int(ent, EV_INT_iuser3) == get_user_team(id))
                continue
            if (get_entity_distance(id, ent) > 140)
                continue
            if (entity_get_int(ent, EV_INT_iuser1)) continue
            new Float:fOrigin[3]
            entity_get_vector(ent, EV_VEC_origin, fOrigin)
            while (PointContents(fOrigin) == CONTENTS_SOLID)
                fOrigin[2] += 100.0
            entity_set_vector(ent, EV_VEC_origin, fOrigin)
            drop_to_floor(ent)
            new Float:fVelocity[3]
            entity_get_vector(ent, EV_VEC_velocity, fVelocity)
            fVelocity[2] += 280.0
            entity_set_vector(ent, EV_VEC_velocity, fVelocity)
            entity_set_int(ent, EV_INT_iuser1, 1)
            grenade_traps_count[pev(ent, pev_owner)]--
            new param[1]
            param[0] = ent
            set_task(0.5, "task_explode_nade", 0, param, 1)
        }
    }
    entity_set_float(bot, EV_FL_nextthink, halflife_time() + 0.01)
}

public task_explode_nade(param[]) {
    if (is_valid_ent(param[0])) {
        entity_set_int(param[0], EV_INT_iuser4, 0)
        entity_set_float(param[0], EV_FL_nextthink, halflife_time() + 0.01)
    }
}

// forums.alliedmods.net/showpost.php?p=591365&postcount=2
public forward_setmodel(ent, model[]) {
    if (!pev_valid(ent))
        return FMRES_IGNORED
    new id = pev(ent, pev_owner)
    if (is_user_connected(id) && (has_healing_grenades[id] && equali(model, "models/w_smokegrenade.mdl") || has_repeling_grenades[id] && equali(model, "models/w_flashbang.mdl"))) {
        set_pev(ent, pev_nextthink, 99999.0)
        if (equali(model, "models/w_smokegrenade.mdl")) {
            ent = -ent
            healing_grenades_count[id]++
        } else {
            repeling_grenades_count[id]++
        }
        set_task(0.5, "check_origin", ent)
    }
    return FMRES_IGNORED
}

public check_origin(ent) {
    new model[55]
    new _ent = ent
    if (ent < 0) {
        ent = -ent
        model = "models/w_smokegrenade.mdl"
    } else {
        model = "models/w_flashbang.mdl"
    }
    if (!is_valid_ent(ent))
        return
    new id = pev(ent, pev_owner)
    new origin[3], float:velocity[3]
    pev(ent, pev_origin, origin)
    pev(ent, pev_velocity, velocity)
    if (velocity[2]) {
        set_task(0.5, "check_origin", _ent)
    } else {
        engfunc(EngFunc_RemoveEntity, ent)
        new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
        set_pev(ent, pev_origin, {0.0, 0.0, 0.0})
        dllfunc(DLLFunc_Spawn, ent)
        set_pev(ent, pev_classname, "grenade_totem")
        set_pev(ent, pev_owner, id)
        set_pev(ent, pev_solid, SOLID_TRIGGER)
        set_pev(ent, pev_origin, origin)
        if (_ent < 0)
            set_pev(ent, pev_ltime, halflife_time() + HEALING_GRENADE_LIFE + 0.1)
        else
            set_pev(ent, pev_ltime, halflife_time() + REPELING_GRENADE_LIFE + 0.1)
        engfunc(EngFunc_SetModel, ent, model)
        set_pev(ent, pev_nextthink, halflife_time() + 0.1)
    }
}

public grenade_totem_think(ent) {
    new id = pev(ent, pev_owner)
    new model[55], grenade_type, grenade_dist
    pev(ent, pev_model, model, charsmax(model))
    if (equali(model, "models/w_smokegrenade.mdl")) {
        grenade_type = 1
        grenade_dist = HEALING_GRENADE_DISTANCE
    } else {
        grenade_type = 2
        grenade_dist = REPELING_GRENADE_DISTANCE
    }
    if (pev(ent, pev_euser2) == 1) {
        new Float:forigin[3], origin[3], players[32], players_count
        pev(ent, pev_origin, forigin)
        FVecIVec(forigin, origin)
        get_players(players, players_count, "ah")
        for (new i = 0; i < players_count; i++) {
            new pid = players[i]
            new Float:player_origin[3]
            pev(pid, pev_origin, player_origin)
            player_origin[2] = forigin[2]
            if (vector_distance(forigin, player_origin) > grenade_dist)
                continue
            if (grenade_type == 1) {
                new old_health = get_user_health(pid)
                new new_health = min(old_health + GRENADE_HEAL, has_extra_hp[pid] ? 100 + GRENADE_OVERHEAL + EXTRA_HP : 100 + GRENADE_OVERHEAL)
                set_user_armor(pid, 100)
                if (old_health != new_health)
                    set_user_health(pid, new_health)
                else
                    continue
            } else if (!get_user_noclip(pid))
                disorient(id, pid, true)
            else
                continue
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin)
            write_byte(TE_BEAMENTS)
            write_short(ent)
            write_short(pid)
            write_short(sprite_lightning)
            write_byte(0)  // start frame
            write_byte(0)  // framerate
            write_byte(10)  // life
            write_byte(50)  // width
            write_byte(1)  // noise
            if (grenade_type == 1) {
                write_byte(HEAL_COLOR[0])
                write_byte(HEAL_COLOR[1])
                write_byte(HEAL_COLOR[2])
            } else {
                write_byte(REPEL_COLOR[0])
                write_byte(REPEL_COLOR[1])
                write_byte(REPEL_COLOR[2])
            }
            write_byte(100)  // brightness
            write_byte(10)  // speed
            message_end()
        }
        set_pev(ent, pev_euser2, 0)
        if (grenade_type == 1)
            set_pev(ent, pev_nextthink, halflife_time() + HEALING_GRENADE_TIME)
        else
            set_pev(ent, pev_nextthink, halflife_time() + REPELING_GRENADE_TIME)
        return PLUGIN_CONTINUE
    }

    // Entity should be destroyed because livetime is over
    if (pev(ent, pev_ltime) < halflife_time() || !is_user_connected(id)) {
        if (grenade_type == 1)
            healing_grenades_count[id]--
        else
            repeling_grenades_count[id]--
        remove_entity(ent)
        return PLUGIN_CONTINUE
    }

    // If this object is almost dead, apply some render to make it fade out
    if (pev(ent, pev_ltime) - 2.0 < halflife_time())
        set_rendering (ent, kRenderFxNone, 255, 255, 255, kRenderTransTexture, 100)

    new Float:forigin[3], origin[3]
    pev(ent, pev_origin, forigin)
    FVecIVec(forigin, origin)
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin)
    write_byte(TE_BEAMCYLINDER)
    write_coord(origin[0])
    write_coord(origin[1])
    write_coord(origin[2])
    write_coord(origin[0])
    write_coord(origin[1])
    write_coord(origin[2] + grenade_dist - 40)
    write_short(sprite_lightning)
    write_byte(0)  // startframe
    write_byte(0)  // framerate
    write_byte(10)  // life
    write_byte(100)  // width
    write_byte(255)  // noise
    if (grenade_type == 1) {
        write_byte(HEAL_COLOR[0])
        write_byte(HEAL_COLOR[1])
        write_byte(HEAL_COLOR[2])
    } else {
        write_byte(REPEL_COLOR[0])
        write_byte(REPEL_COLOR[1])
        write_byte(REPEL_COLOR[2])
    }
    write_byte(150)  // brightness
    write_byte(5)  // speed
    message_end()
    set_pev(ent, pev_euser2, 1)
    set_pev(ent, pev_nextthink, halflife_time() + 0.5)
    return PLUGIN_CONTINUE
}
//-----------------------------------------------------------------------------
// sh_spiderman.sma forums.alliedmods.net/showthread.php?t=76081
const HOOK_BEAM_LIFE = 100
const Float:HOOK_DELTA_T = 0.1

public cast_hook(id) {
    new user_origin[3]
    get_user_origin(id, user_origin)
    get_user_origin(id, hook_location[id], 3)
    hook_length[id] = get_distance(hook_location[id], user_origin)
    set_user_gravity(id, 0.001)
    beamentpoint(id)
    if (hooked[id] == 1) {
        set_task(HOOK_DELTA_T, "hook_spider_web", id + HOOK_TASK, _, _, "b")
        emit_sound(id, CHAN_STATIC, "bullchicken/bc_bite2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    } else if (hooked[id] == 2) {
        set_task(HOOK_DELTA_T, "hook_grippling_hook", id + HOOK_TASK, _, _, "b")
        emit_sound(id, CHAN_STATIC, "weapons/xbow_fire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH)
        set_e_charging(id, HOOK_CHARGING_TIME)
    }
}

public hook_spider_web(task_id) {
    new id = task_id - HOOK_TASK
    if (hooked[id] != 1) return
    if (!is_user_alive(id)) {
        hook_off(id)
        return
    }
    if (hook_created[id] + HOOK_BEAM_LIFE / 10 <= get_gametime()) {
        beamentpoint(id)
    }
    new user_origin[3], null[3], A[3], D[3], buttonadjust[3], buttonpress
    new Float:vTowards_A, Float:DvTowards_A, Float:velocity[3]
    get_user_origin(id, user_origin)
    pev(id, pev_velocity, velocity)
    buttonpress = pev(id, pev_button)
    if (buttonpress & IN_FORWARD) ++buttonadjust[0]
    if (buttonpress & IN_BACK) --buttonadjust[0]
    if (buttonpress & IN_MOVERIGHT) ++buttonadjust[1]
    if (buttonpress & IN_MOVELEFT) --buttonadjust[1]
    if (buttonpress & IN_JUMP) ++buttonadjust[2]
    if (buttonpress & IN_DUCK) --buttonadjust[2]
    if (buttonadjust[0] || buttonadjust[1]) {
        new user_look[3], move_direction[3]
        get_user_origin(id, user_look, 2)
        user_look[0] -= user_origin[0]
        user_look[1] -= user_origin[1]
        move_direction[0] = buttonadjust[0] * user_look[0] + user_look[1] * buttonadjust[1]
        move_direction[1] = buttonadjust[0] * user_look[1] - user_look[0] * buttonadjust[1]
        move_direction[2] = 0
        new move_dist = get_distance(null, move_direction)
        new Float:accel = 140 * HOOK_DELTA_T
        velocity[0] += move_direction[0] * accel / move_dist
        velocity[1] += move_direction[1] * accel / move_dist
    }
    if (buttonadjust[2] < 0 || (buttonadjust[2] && hook_length[id] >= 60)) {
        hook_length[id] -= floatround(buttonadjust[2] * SPIDER_WEB_SPEED * HOOK_DELTA_T)
    }
    else if (!(buttonpress & IN_DUCK) && hook_length[id] >= 200) {
        buttonadjust[2] += 1
        hook_length[id] -= floatround(buttonadjust[2] * SPIDER_WEB_SPEED * HOOK_DELTA_T)
    }
    A[0] = hook_location[id][0] - user_origin[0]
    A[1] = hook_location[id][1] - user_origin[1]
    A[2] = hook_location[id][2] - user_origin[2]
    new distA = get_distance(null, A)
    distA = distA ? distA : 1  // Avoid dividing by 0
    vTowards_A = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / distA
    DvTowards_A = float((get_distance(user_origin, hook_location[id]) - hook_length[id]) * 4)
    D[0] = A[0]*A[2] / distA
    D[1] = A[1]*A[2] / distA
    D[2] = -(A[1]*A[1] + A[0]*A[0]) / distA
    new distD = get_distance(null, D)
    if (distD > 10) {
        new Float:acceleration = ((-get_cvar_num("sv_gravity")) * D[2] / distD) * HOOK_DELTA_T
        velocity[0] += (acceleration * D[0]) / distD
        velocity[1] += (acceleration * D[1]) / distD
        velocity[2] += (acceleration * D[2]) / distD
    }
    new Float:difference = DvTowards_A - vTowards_A
    velocity[0] += (difference * A[0]) / distA
    velocity[1] += (difference * A[1]) / distA
    velocity[2] += (difference * A[2]) / distA
    set_pev(id, pev_velocity, velocity)
}

public hook_grippling_hook(task_id) {
    new id = task_id - HOOK_TASK
    if (hooked[id] != 2) return
    if (!is_user_alive(id)) {
        hook_off(id)
        return
    }
    new user_origin[3]
    new Float:velocity[3]
    get_user_origin(id, user_origin)
    new distance = get_distance(hook_location[id], user_origin)
    if (distance > 60) {
        new Float:inverseTime = HOOK_SPEED / distance
        velocity[0] = (hook_location[id][0] - user_origin[0]) * inverseTime
        velocity[1] = (hook_location[id][1] - user_origin[1]) * inverseTime
        velocity[2] = (hook_location[id][2] - user_origin[2]) * inverseTime
    }
    set_pev(id, pev_velocity, velocity)
}

hook_off(id) {
    hooked[id] = 0
    killbeam(id)
    if (is_user_alive(id)) {
        set_user_gravity(id, 1.0)
        give_buffs(id)
    }
    remove_task(HOOK_TASK + id)
}

beamentpoint(id) {
    if (!is_user_connected(id)) return
    new rgb[3] = {250, 250, 250}
    if (has_spider_web[id])
        rgb = {255, 255, 255}
    else if (cs_get_user_team(id) == CS_TEAM_T)
        rgb = {255, 0, 0}
    else
        rgb = {0, 0, 255}
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMENTPOINT)
    write_short(id)
    write_coord(hook_location[id][0])
    write_coord(hook_location[id][1])
    write_coord(hook_location[id][2])
    write_short(sprite_line)  // sprite index
    write_byte(0)  // start frame
    write_byte(0)  // framerate
    write_byte(HOOK_BEAM_LIFE)// life
    write_byte(10)  // width
    write_byte(0)  // noise
    write_byte(rgb[0])  // r, g, b
    write_byte(rgb[1])  // r, g, b
    write_byte(rgb[2])  // r, g, b
    write_byte(150)  // brightness
    write_byte(0)  // speed
    message_end()
    hook_created[id] = get_gametime()
}

killbeam(id) {
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_KILLBEAM)
    write_short(id)
    message_end()
}
//-----------------------------------------------------------------------------
// sh_scorpion.sma forums.alliedmods.net/showthread.php?t=34448
public cast_harpoon(id) {
    if (!is_user_alive(id)) return
    new victim, body
    get_user_aiming(id, victim, body)
    if (is_user_alive(victim)) {
        hit_with_harpoon[id] = victim
        emit_sound(victim, CHAN_BODY, "weapons/xbow_hitbod1.wav", 0.6, ATTN_NORM, 0, PITCH_HIGH)
        new parm[2]
        parm[0] = id
        parm[1] = victim
        set_task(0.1, "harpoon_reelin", HARPOON_REELIN_TASK + id, parm, 2, "b")
        harpoon_target(parm)
    }
    else {
        hit_with_harpoon[id] = 33
        harpoon_notarget(id)
    }
}

public harpoon_reelin(parm[]) {
    new id = parm[0]
    new victim = parm[1]
    if (!hit_with_harpoon[id]) return
    if (!is_user_alive(victim)) {
        harpoon_off(id)
        return
    }
    set_task(6.0, "harpoon_escape", HARPOON_ESCAPE_TASK + id)
    new Float:fl_Velocity[3]
    new idOrigin[3], vicOrigin[3]
    get_user_origin(victim, vicOrigin)
    get_user_origin(id, idOrigin)
    new distance = get_distance(idOrigin, vicOrigin)
    if (abs(idOrigin[0] - vicOrigin[0]) > 40 || abs(idOrigin[1] - vicOrigin[1]) > 40 || abs(idOrigin[2] - vicOrigin[2]) > 75) {
        new Float:fl_Time = distance / HARPOON_SPEED
        fl_Velocity[0] = (idOrigin[0] - vicOrigin[0]) / fl_Time
        fl_Velocity[1] = (idOrigin[1] - vicOrigin[1]) / fl_Time
        fl_Velocity[2] = (idOrigin[2] - vicOrigin[2]) / fl_Time
    } else {
        fl_Velocity[0] = 0.0
        fl_Velocity[1] = 0.0
        fl_Velocity[2] = 0.0
        if (!is_user_alive(id) || !is_user_alive(victim))
            return
        if (has_harpoon[id] && hit_with_harpoon[id] == victim) {
            set_task(0.1, "uppercut", _, parm, 2)
        }
        harpoon_off(id)
    }
    entity_set_vector(victim, EV_VEC_velocity, fl_Velocity)
}

public harpoon_off(id) {
    new victim = hit_with_harpoon[id]
    if (is_user_connected(hit_with_harpoon[id])) {
        disoriented_by[victim] = id
        set_task(3.0, "disorient_mark", DISORIENTED_TASK + victim)
    }
    hit_with_harpoon[id] = 0
    killbeam(id)
    remove_task(HARPOON_ESCAPE_TASK + id)
    remove_task(HARPOON_REELIN_TASK + id)
}

public harpoon_escape(task_id)
    harpoon_off(task_id - HARPOON_ESCAPE_TASK)

public uppercut(parm[]) {
    new id = parm[0]
    new vic = parm[1]
    if (!is_user_alive(vic)) return
    new Origin[3], vicOrigin[3]
    get_user_origin(id, Origin)
    get_user_origin(vic, vicOrigin)
    emit_sound(vic, CHAN_BODY, "player/headshot3.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
    new Float:fl_Time = get_distance(vicOrigin, Origin) / 300.0
    new Float:fl_vicVelocity[3]
    fl_vicVelocity[0] = (vicOrigin[0] - Origin[0]) / fl_Time
    fl_vicVelocity[1] = (vicOrigin[1] - Origin[1]) / fl_Time
    fl_vicVelocity[2] = 450.0
    entity_set_vector(vic, EV_VEC_velocity, fl_vicVelocity)
}

public harpoon_target(parm[]) {
    new id = parm[0]
    new victim = parm[1]
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(8)  // TE_BEAMENTS
    write_short(id)
    write_short(victim)
    write_short(sprite_line)  // sprite index
    write_byte(0)  // start frame
    write_byte(0)  // framerate
    write_byte(200)  // life
    write_byte(6)  // width
    write_byte(1)  // noise
    write_byte(255)  // r, g, b
    write_byte(255)  // r, g, b
    write_byte(25)  // r, g, b
    write_byte(255)  // brightness
    write_byte(10)  // speed
    message_end()
}

public harpoon_notarget(id) {
    new endorigin[3]
    get_user_origin(id, endorigin, 3)
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(1)  // TE_BEAMENTPOINT
    write_short(id)
    write_coord(endorigin[0])
    write_coord(endorigin[1])
    write_coord(endorigin[2])
    write_short(sprite_line)  // sprite index
    write_byte(0)  // start frame
    write_byte(0)  // framerate
    write_byte(200)  // life
    write_byte(6)  // width
    write_byte(1)  // noise
    write_byte(255)  // r, g, b
    write_byte(255)  // r, g, b
    write_byte(25)  // r, g, b
    write_byte(100)  // brightness
    write_byte(0)  // speed
    message_end()
}
//-----------------------------------------------------------------------------
// forums.alliedmods.net/showthread.php?t=23691
public flashlight_esp() {
    static players[32], players_count, id
    get_players(players, players_count)
    for (new i = 0; i < players_count; i++) {
        id = players[i]
        if (!is_user_connected(id))
            continue
        new target = f_target[is_user_alive(id) ? id : pev(id, pev_iuser2)]
        if (!target)
            continue
        static Float:origin[3], Float:target_origin[3], Float:middle[3],
               Float:hitpoint[3], Float:bone_start[3]
        pev(is_user_alive(id) ? id : pev(id, pev_iuser2), pev_origin, origin)
        pev(target, pev_origin, target_origin)
        new Float:distance = vector_distance(origin, target_origin)
        middle[0] = target_origin[0] - origin[0]
        middle[1] = target_origin[1] - origin[1]
        middle[2] = target_origin[2] - origin[2]
        trace_line(-1, origin, target_origin, hitpoint)
        new Float:distance_to_hitpoint = vector_distance(origin, hitpoint)
        if (distance_to_hitpoint == distance)
            continue
        new Float:len = vector_distance(middle, Float:{0.0, 0.0, 0.0})
        bone_start[0] = middle[0] / len * (distance_to_hitpoint - 10.0) + origin[0]
        bone_start[1] = middle[1] / len * (distance_to_hitpoint - 10.0) + origin[1]
        bone_start[2] = middle[2] / len * (distance_to_hitpoint - 10.0) + origin[2] + 17.5
        message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id)
        write_byte(0)
        write_coord(floatround(bone_start[0]))
        write_coord(floatround(bone_start[1]))
        write_coord(floatround(bone_start[2]))
        write_coord(floatround(bone_start[0]))
        write_coord(floatround(bone_start[1]))
        write_coord(floatround(bone_start[2] - distance_to_hitpoint / distance * 50.0))
        write_short(sprite_line)
        write_byte(1)
        write_byte(1)
        write_byte(1)
        write_byte(floatround(distance_to_hitpoint / distance * 150.0))
        write_byte(0)
        write_byte(0)
        write_byte(255)
        write_byte(0)
        write_byte(max(85, (255-floatround(distance / 12.0))))
        write_byte(0)
        message_end()
    }
}
//-----------------------------------------------------------------------------
// forums.alliedmods.net/showthread.php?t=30095
public electroshock_search(task_id) {
    new id = task_id - CAST_F_TASK
    if (f_searching[id]) {
        emit_sound(id, CHAN_STATIC, "turret/tu_ping.wav", 0.5, ATTN_NORM, 0, PITCH_NORM)
        set_task(1.0, "electroshock_search", task_id)
    }
}

public forward_traceline(Float:start[3], Float:end[3], const no_monsters, const id, const handle_trace_result) {
    new victim = get_tr2(handle_trace_result, TR_pHit)
    if (!is_user_alive(victim) || !is_user_alive(id) || cs_get_user_team(id) == cs_get_user_team(victim))
        return FMRES_IGNORED
    if (pev(id, pev_effects) & EF_DIMLIGHT)
        set_f_target(id, victim)
    else if (has_electroshock[id] && f_searching[id] && !get_user_noclip(victim)) {
        new Float:beamOrigin[3]
        pev(id, pev_origin, beamOrigin)
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(TE_BEAMENTS)
        write_short(id)  // start entity
        write_short(victim)  // entity
        write_short(sprite_lightning)  // model
        write_byte(0)  // starting frame
        write_byte(15)  // frame rate
        write_byte(10)  // life
        write_byte(50)  // line width
        write_byte(10)  // noise amplitude
        write_byte(REPEL_COLOR[0])
        write_byte(REPEL_COLOR[1])
        write_byte(REPEL_COLOR[2])
        write_byte(200)  // brightness
        write_byte(0)  // scroll speed
        message_end()
        disorient(id, victim, false)
        emit_sound(id, CHAN_STATIC, "weapons/gauss2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        f_searching[id] = false
        set_f_cooldown(id, ELECTROSHOCK_COOLDOWN)
    }
    return FMRES_IGNORED
}

public disorient(attacker, victim, repel) {
    new Float:velocity[3]
    if (repel) {
        velocity[0] = 200.0 * random_num(-3, 3)
        velocity[1] = 200.0 * random_num(-3, 3)
        velocity[2] = 200.0 * random_num(1, 5)
    } else {
        velocity[0] = 75.0 * random_num(-3, 3)
        velocity[1] = 75.0 * random_num(-3, 3)
        velocity[2] = 200.0
    }
    if (has_ghost[victim] || has_spider_web[victim] || has_hook[victim] || has_parachute[victim])
        set_e_cooldown(victim, floatmax(DISORIENT_COOLDOWNS_TIME, e_cooldown[victim]), e_in_progress[victim])
    if (has_leap[victim])
        set_f_cooldown(victim, floatmax(DISORIENT_COOLDOWNS_TIME, f_cooldown[victim]))
    fm_set_user_velocity(victim, velocity)
    disoriented_by[victim] = attacker
    set_task(3.0, "disorient_mark", DISORIENTED_TASK + victim)
    if (hooked[victim] == 2) {
        client_cmd(victim, "-use")
        set_task(0.3, "set_velocity", VELOCITY_TASK + victim, velocity, 3)
    } else {
        client_cmd(victim, "-use")
        fm_set_user_velocity(victim, velocity)
    }
}

public set_velocity(task_id, Float:velocity[3]) {
    new id = task_id - VELOCITY_TASK
    if (is_user_alive(id))
        fm_set_user_velocity(id, velocity)
}

public disorient_mark()
    return
//-----------------------------------------------------------------------------
// forums.alliedmods.net/showpost.php?p=1636393&postcount=5
const XO_WEAPON = 4
const m_pPlayer = 41
const m_flNextPrimaryAttack = 46

public hegrenade_attack(grenade_index) {
    new id = get_pdata_cbase(grenade_index, m_pPlayer, XO_WEAPON)
    if (grenade_traps_count[id] >= GRENADE_TRAPS_LIMIT) {
        set_pdata_float(grenade_index, m_flNextPrimaryAttack, 1.0, XO_WEAPON)
        client_print(id, print_chat, "%L", id, "SKILLS_TOO_MANY_GRENADES", GRENADE_TRAPS_LIMIT)
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}

public smokegrenade_attack(grenade_index) {
    new id = get_pdata_cbase(grenade_index, m_pPlayer, XO_WEAPON)
    if (healing_grenades_count[id] >= HEALING_GRENADES_LIMIT) {
        set_pdata_float(grenade_index, m_flNextPrimaryAttack, 1.0, XO_WEAPON)
        client_print(id, print_chat, "%L", id, "SKILLS_TOO_MANY_GRENADES", HEALING_GRENADES_LIMIT)
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}

public flashbang_attack(grenade_index) {
    new id = get_pdata_cbase(grenade_index, m_pPlayer, XO_WEAPON)
    if (repeling_grenades_count[id] >= REPELING_GRENADES_LIMIT) {
        set_pdata_float(grenade_index, m_flNextPrimaryAttack, 1.0, XO_WEAPON)
        client_print(id, print_chat, "%L", id, "SKILLS_TOO_MANY_GRENADES", REPELING_GRENADES_LIMIT)
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}
//-----------------------------------------------------------------------------
public skills_menu(id) {
    menu_shown[id] = true
    new string[128], menu
    if (skills_count[id] < 3) {
        formatex(string, 128, "%L", id, "SKILLS_MENU_TITLE_PASSIVE")
        menu = menu_create(string, "skills_menu_handler")
        menu_setprop(menu, MPROP_TITLE, string)
        for (new i = 0; i < 13; i++) {
            new bool:f = false
            for (new j = 0; j < skills_count[id]; j++)
                if (i == skills_selected[id][j]) {
                    #if AMXX_VERSION_NUM < 183
                    formatex(string, 128, "\d%L\w", id, names[i])
                    menu_additem(menu, string)
                    #else
                    formatex(string, 128, "\d%d. %L\w", i % 7 + 1, id, names[i])
                    menu_addtext2(menu, string)
                    #endif
                    f = true
                    break
                }
            if (!f) {
                formatex(string, 128, "%L", id, names[i])
                menu_additem(menu, string)
            }
        }
        formatex(string, 100, "%L", id, "SKILLS_MENU_BACK")
        menu_setprop(menu, MPROP_BACKNAME, string)
        formatex(string, 100, "%L", id, "SKILLS_MENU_NEXT")
        menu_setprop(menu, MPROP_NEXTNAME, string)
        formatex(string, 100, "%L", id, "SKILLS_MENU_EXIT")
        menu_setprop(menu, MPROP_EXITNAME, string)
        menu_setprop(menu, MPROP_SHOWPAGE, 0)
        menu_display(id, menu, menu_page[id])
    } else {
        if (skills_count[id] == 3) {
            formatex(string, 128, "%L", id, "SKILLS_MENU_TITLE_ACTIVE1")
            menu = menu_create(string, "skills_menu_handler")
            for (new i = 0; i < 6; i++) {
                formatex(string, 128, "%L", id, names[i + passive_count])
                menu_additem(menu, string)
            }
        } else {
            formatex(string, 128, "%L", id, "SKILLS_MENU_TITLE_ACTIVE2")
            menu = menu_create(string, "skills_menu_handler")
            for (new i = 0; i < 5; i++) {
                formatex(string, 128, "%L", id, names[i + passive_count + active1_count])
                menu_additem(menu, string)
            }
        }
        formatex(string, 100, "%L", id, "SKILLS_MENU_EXIT")
        menu_setprop(menu, MPROP_EXITNAME, string)
        menu_display(id, menu)
    }
    return PLUGIN_HANDLED
}

public skills_menu_handler(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    new command[10], name[64], access, callback
    menu_item_getinfo(menu, item, access, command, sizeof command - 1, name, sizeof name - 1, callback)
    if (skills_count[id] == 3) {
        e_cooldown[id] = 0.0
        e_charges[id] = 0
        e_max_charges[id] = 0
        give_active1(id, item + passive_count)
        client_print(id, print_chat, "%L", id, "SKILLS_ACTIVE1_TIP", name)
    } else if (skills_count[id] == 4) {
        f_cooldown[id] = 0.0
        give_active2(id, item + passive_count + active1_count)
        client_print(id, print_chat, "%L", id, "SKILLS_ACTIVE2_TIP", name)
        client_print(id, print_chat, "%L", id, "SKILLS_RESET_TIP")
    } else {
        if (item > 6)
            menu_page[id] = 1
        else
            menu_page[id] = 0
        #if AMXX_VERSION_NUM < 183
        for (new j = 0; j < skills_count[id]; j++)
            if (item == skills_selected[id][j]) {
                menu_destroy(menu)
                skills_menu(id)
                return PLUGIN_HANDLED
            }
        #endif
        give_passive(id, item)
        client_print(id, print_chat, "%L", id, "SKILLS_PASSIVE_TIP", name)
    }
    give_buffs(id)
    menu_destroy(menu)
    if (skills_count[id] < 5)
        skills_menu(id)
    return PLUGIN_HANDLED
}

give_active1(id, skill) {
    switch (skill) {
        case 14: has_harpoon[id] = true
        case 16: has_parachute[id] = true
        case 17: has_spider_web[id] = true
        case 13: has_ghost[id] = true
        case 15: {
            has_hook[id] = true
            e_charges[id] = HOOK_CHARGES
            e_max_charges[id] = HOOK_CHARGES
        }
        case 18: {
            client_cmd(id, "cl_forwardspeed 2000;cl_sidespeed 2000;cl_backspeed 2000")
            has_sprint[id] = true
        }
    }
    skills_selected[id][skills_count[id]] = skill
    skills_count[id]++
}

give_active2(id, skill) {
    switch (skill) {
        case 21: has_leap[id] = true
        case 20: has_disarm[id] = true
        case 19: has_free_grenades[id] = true
        case 23: has_flashlight[id] = true
        case 22: has_electroshock[id] = true
    }
    skills_selected[id][skills_count[id]] = skill
    skills_count[id]++
}

give_passive(id, skill) {
    switch (skill) {
        case 0: has_antigravity[id] = true
        case 12: has_triple_jumps[id] = true
        case 1: has_silent_footsteps[id] = true
        case 2: has_wealthiness[id] = true
        case 4: has_ammo_resupply[id] = true
        case 8: {
            has_extra_hp[id] = true
            set_user_health(id, get_user_health(id) + EXTRA_HP)
        }
        case 11: has_life_steal[id] = true
        case 7: {
            has_extra_life[id] = true
            used_extra_life[id] = false
        }
        case 5: {
            has_grenade_traps[id] = true
            give_item(id, "weapon_hegrenade")
        }
        case 6: {
            has_repeling_grenades[id] = true
            give_item(id, "weapon_flashbang")
            cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
        }
        case 10: {
            has_healing_grenades[id] = true
            give_item(id, "weapon_smokegrenade")
        }
        case 9: has_fall_protection[id] = true
        case 3: has_side_jump[id] = true
    }
    skills_selected[id][skills_count[id]] = skill
    skills_count[id]++
}

#if defined BOTS_HAVE_SKILLS
public give_skills_to_bot(id) {
    static const bot_passive[8] = {0, 1, 4, 5, 6, 8, 9, 11}
    for (new i = 0; i < 3; i++) {
        new skill = bot_passive[random(8)]
        new bool:can_pick = true
        for (new j = 0; j < skills_count[id]; j++)
            if (skill == skills_selected[id][j]) {
                i--
                can_pick = false
                break
            }
        if (can_pick)
            give_passive(id, skill)
    }
    give_buffs(id)
    give_active1(id, 18)
    give_active2(id, passive_count + active1_count + random(3))
    set_task(2.0, "bots_press_buttons", id + BOT_TASK, _, _, "b")
}

public bots_press_buttons(task_id) {
    new id = task_id - BOT_TASK
    if (!is_user_alive(id))
        return
    if (!e_cooldown[id] && !random(2))
        pressed_e(id + PRESS_E_TASK)
    if (!f_cooldown[id] && !random(2))
        client_impulse(id, 100)
}
#endif
