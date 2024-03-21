#include "CKiaiAmmo"
#include "MapUtils"
#include "weapon_merikensack"
#include "weapon_shinai"
#include "weapon_bokutou"
#include "weapon_bat"
#include "weapon_metalbat"
#include "weapon_nailbat"
#include "weapon_brush"
#include "weapon_fryingpan"
#include "weapon_ironpipe"
#include "weapon_kakuzai"
#include "weapon_shovel"
#include "weapon_monkeywrench"
#include "weapon_hockeystick"
#include "weapon_tennisracket"
#include "weapon_goldbar"
#include "weapon_platinumbar"

// ユーティリティクラス
MapUtils g_utils;

int g_sprite; // sprite
bool isFiredForScript = false;

// タイマー
CScheduledFunction@ g_pTimer = null;
const float INTERVAL = 5.0;

const array<string> g_sinSoundList = {
    "uboa_rampage/bahhh.wav",
    "uboa_rampage/waaa.wav"
};

/** マップ初期化 */
void MapInit() {
    isFiredForScript = false;
    
    // プリキャッシュ
    for (uint i = 0; i < g_sinSoundList.length(); i++) {
        g_Game.PrecacheGeneric("sound/" + g_sinSoundList[i]);
        g_SoundSystem.PrecacheSound(g_sinSoundList[i]);
    }
 
    g_sprite = g_Game.PrecacheModel("sprites/laserbeam.spr");
    
    // Hook
    g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @PlayerJoin);
    g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @PlayerSpawn);
    g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @PlayerKilled);
    
    
    // 武器登録
    RegisterMerikenSack();
    RegisterShinai();
    RegisterBokutou();
    RegisterBat();
    RegisterMetalbat();
    RegisterNailbat();
    RegisterBrush();
    RegisterFryingpan();
    RegisterIronpipe();
    RegisterKakuzai();
    RegisterShovel();
    RegisterMonkeyWrench();
    RegisterHockeyStick();
    RegisterTennisRacket();
    RegisterGoldbar();
    RegisterPlatinumbar();
    
    // 気力
    RegisterKiaiAmmo();
    // 耐久力
    RegisterDurabilityAmmo();
    
    @g_pTimer = g_Scheduler.SetInterval("CheckTimer", INTERVAL);
        
    g_EngineFuncs.ServerPrint("[map script] scripts working! ....(^^;)b\n");    
}


// エラーチェック処理
void ErrorCheck() {    
    // スクリプトエラーでなければ、該当Entityを削除する
    CBaseEntity@ pTarget = null;  
    @pTarget = g_EntityFuncs.FindEntityByTargetname(pTarget, "wl_errchk");
    if (pTarget !is null) {
        g_EntityFuncs.Remove(pTarget);
    }
}

// アイテム発光
void GrowItems() {    
    // medkitやarmor
    const array<string> itemName = { "item_healthkit", "item_battery" };
    CBaseEntity@ pTarget = null;
    for (uint i = 0; i < itemName.length(); i++) {
        while ((@pTarget = g_EntityFuncs.FindEntityByClassname( pTarget, itemName[i] )) !is null) {
            pTarget.pev.rendermode  = kRenderNormal;
            pTarget.pev.renderfx    = kRenderFxGlowShell;
            pTarget.pev.renderamt   = 4;
            pTarget.pev.rendercolor = Vector(128, 128, 128);
        }
    }
}

/** プレイヤー参加時 */
HookReturnCode PlayerJoin( CBasePlayer@ pPlayer ) {
    
    if (!isFiredForScript) {
        ErrorCheck();
        GrowItems();
        isFiredForScript = true;
    }
    return HOOK_CONTINUE;
}

/** プレイヤーSpawn */
HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer) {
    
    g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_AUTO, g_sinSoundList[0], 1.0f, ATTN_NORM, 0, 100);
    
    int r = Math.RandomLong(0, 255);
    int g = Math.RandomLong(0, 255);
    int b = Math.RandomLong(0, 255);
    
    // 波動
    NetworkMessage messageWave(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
    messageWave.WriteByte(TE_BEAMCYLINDER);
    messageWave.WriteCoord(pPlayer.pev.origin.x);
    messageWave.WriteCoord(pPlayer.pev.origin.y);
    messageWave.WriteCoord(pPlayer.pev.origin.z);
    messageWave.WriteCoord(pPlayer.pev.origin.x);
    messageWave.WriteCoord(pPlayer.pev.origin.y);
    messageWave.WriteCoord(pPlayer.pev.origin.z + 100);
    messageWave.WriteShort(g_sprite);
    messageWave.WriteByte(0);
    messageWave.WriteByte(16);
    messageWave.WriteByte(8);
    messageWave.WriteByte(8);
    messageWave.WriteByte(0);
    messageWave.WriteByte(r);
    messageWave.WriteByte(g);
    messageWave.WriteByte(b);
    messageWave.WriteByte(100);
    messageWave.WriteByte(0);
    messageWave.End();
    
    return HOOK_CONTINUE;
}

/** 死亡時 */
HookReturnCode PlayerKilled (CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib) {
    g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_VOICE, g_sinSoundList[1], 1.0f, ATTN_NORM, 0, 100);
    return HOOK_CONTINUE;
}


// タイマー
void CheckTimer() {
    g_utils.Tick();
}
