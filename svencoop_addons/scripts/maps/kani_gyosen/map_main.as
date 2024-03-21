/**
 * 蟹漁船 マップスクリプト
 */
#include "weapon_harpoon"
#include "weapon_aps"

#include "func_vehicle_boat"
#include "func_vehicle_controls"
#include "func_vehicle_behavior"

#include "map_gimmick"

bool isFiredScript = false;
bool isDebug = false;

void MapInit() {
    // Hook
    g_Hooks.RegisterHook(Hooks::Player::PlayerUse,         @VehiclePlayerUse);
    g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink,    @VehiclePlayerPreThink);
    g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
    g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect,  @ClientDisconnect);
    g_Hooks.RegisterHook(Hooks::Player::PlayerKilled,      @PlayerKilled);
    
    // プリキャッシュ
    MAP_GIMMICK::Precache();
    
    RegisterBoat();
    RegisterBoatControl();
    
    // 武器登録
    RegisterHarpoon();
    RegisterAps();
    
    // 定期タイマー
    g_Scheduler.SetInterval("CheckTimer", 5.0);
    
    g_EngineFuncs.ServerPrint("[kani_gyosen] map scripts are working! ....(^^;)b\n");
}


//================================================
// プレイヤーサーバー参加時
//================================================
HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer ) {
    MapInitCheck();
    
    return FUNC_VEHICLE::Fv_ClientPutInServer(pPlayer);
}

//================================================
// プレイヤー切断時
//================================================
HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer) {
    
    return FUNC_VEHICLE::Fv_ClientDisconnect(pPlayer);
}

//================================================
// プレイヤー死亡時
//================================================
HookReturnCode PlayerKilled (CBasePlayer@ pPlayer, CBaseEntity@ pEntity, int param) {
    
    return FUNC_VEHICLE::Fv_PlayerKilled(pPlayer, pEntity, param);
}

//================================================
// プレイヤーUSE時
//================================================
HookReturnCode VehiclePlayerUse( CBasePlayer@ pPlayer, uint& out uiFlags ) {
        
    return FUNC_VEHICLE::Fv_VehiclePlayerUse(pPlayer, uiFlags);
}

//================================================
// プレイヤーの定期動作処理（PRE）
//================================================
HookReturnCode VehiclePlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags ) {
    
    return FUNC_VEHICLE::Fv_VehiclePlayerPreThink(pPlayer, uiFlags);
}

//------------------------------------------------
// 初期化処理時処理
//------------------------------------------------
void MapInitCheck() {
    
    if (!isFiredScript) {            
        // スクリプトエラーでなければ、該当Entityを削除する
        array<string> DEL_ENTS = { "wl_errchk", "debug_ent" };
        if (isDebug) {
            DEL_ENTS = { "wl_errchk" };
        }  
        
        CBaseEntity@ pTarget = null;
        for (uint i = 0; i < DEL_ENTS.length(); i++) {
            while ((@pTarget =  g_EntityFuncs.FindEntityByTargetname(pTarget, DEL_ENTS[i])) !is null) {
                g_EntityFuncs.Remove(pTarget);
            }
        }
                    
        isFiredScript = true;
    }
}

//------------------------------------------------
// タイマー
//------------------------------------------------
void CheckTimer() {
    // 呼吸、フラッシュライト無限化
    for (int i = 1; i <= g_Engine.maxClients; i++) {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if ((pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive()) ) {
            pPlayer.pev.air_finished = g_Engine.time + 600;
            pPlayer.m_iFlashBattery = 100;
        }
    }
    
    // カニにすり替える罠
    if ( Math.RandomLong( 0, 7 ) == 0) {
        ReplaceLeechToCrab();
    }
}

//------------------------------------------------
// カニすり替え
//------------------------------------------------
void ReplaceLeechToCrab() {
    Vector pos;
    Vector ang;
    
    CBaseEntity@ pTarget = null;  
    while ((@pTarget = g_EntityFuncs.FindEntityByClassname(pTarget, "monster_babycrab")) !is null) {
        
        // 確率ですり替える
        if ( Math.RandomLong( 0, 9 ) == 0) {
            pos = pTarget.GetOrigin();
            ang = pTarget.pev.angles;
            
            // 罠発動（蓋が閉まる）
            string entName = pTarget.pev.targetname;
            entName.Replace("mon_", "plt_");
            g_EntityFuncs.FireTargets(entName, null, null, USE_OFF);
            
            // 餌削除
            g_EntityFuncs.Remove(pTarget);
            
            // カニ追加
            CBaseEntity @pEntity = g_EntityFuncs.Create( "monster_headcrab",  pos, ang, true);
            g_EntityFuncs.DispatchKeyValue(pEntity.edict(), "displayname", "kani");
            g_EntityFuncs.DispatchKeyValue(pEntity.edict(), "health", "150");
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
        }
    }
    
}

