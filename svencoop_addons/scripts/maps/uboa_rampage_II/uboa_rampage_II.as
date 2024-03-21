//////////////////////////////////////////
//  UBOA RAMPAGE II map script
//////////////////////////////////////////
#include "CUboaAmmo"
#include "CPlayerClassUtil"

#include "weapon_zassi"
#include "weapon_merikensack2"
#include "weapon_sude"
#include "weapon_higonokami"
#include "weapon_gennou"

#include "weapon_ironpipe"
#include "weapon_butterflyknife"
#include "weapon_lucille"
#include "weapon_katana"
#include "weapon_kagizume"
#include "weapon_policebaton"
#include "weapon_tekkotsu"
#include "weapon_pickaxe"
#include "weapon_kanban"
#include "weapon_block"
#include "weapon_guidelight"
#include "weapon_karateglove"
#include "weapon_golfclub"
#include "weapon_kukri"
#include "weapon_kitchenknife"

#include "monster_electro"

const array<string> g_sinSoundList = {
    "uboa_rampage/bahhh.wav",
    "uboa_rampage/waaa.wav"
};

// �X�N���v�g�p������s����
bool isFiredForScript = false;

// �^�C�}�[
CScheduledFunction@ g_pTimer = null;
const float INTERVAL = 5.0;

// ���[�e�B���e�B�N���X
CPlayerClassUtil g_pcUtil;

void MapInit() {
    
    // �v���L���b�V��
    for (uint i = 0; i < g_sinSoundList.length(); i++) {
        g_Game.PrecacheGeneric("sound/" + g_sinSoundList[i]);
        g_SoundSystem.PrecacheSound(g_sinSoundList[i]);
    }
    g_Game.PrecacheModel("sprites/laserbeam.spr");
    
    // Hook
    g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @PlayerJoin);
    g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @PlayerSpawn);
    g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @PlayerKilled);
    
    // �x�[�X����o�^
    RegisterZassi();
    RegisterMerikensack2();
    RegisterSude();
    RegisterHigonokami();
    RegisterGennou();
    
    // �擾����o�^
    RegisterIronpipe();
    RegisterButterflyknife();
    RegisterLucille();    
    RegisterKatana();
    RegisterKagizume();
    RegisterPolicebaton();
    RegisterTekkotsu();
    RegisterPickaxe();
    RegisterKanban();
    RegisterBlock();
    RegisterGuidelight();
    RegisterKarateglove();
    RegisterGolfclub();
    RegisterKukri();
    RegisterKitchenknife();
    
    // �{�X
    RegisterElectro();
    
    // Prop
    RegisterThrowknife();
    RegisterSwordwave();
    RegisterElectroVolt();
    
    // Ammo
    RegisterKiaiAmmo();
    RegisterWazaAmmo();
    RegisterPlayerClassAmmo();
    
    // �����_���G���e�B�e�B
    RegisterInfoRandomWeapon();
    
    @g_pTimer = g_Scheduler.SetInterval("CheckTimer", INTERVAL);
    
    g_EngineFuncs.ServerPrint("[map script] scripts working! ....(^^;)b\n");
}

// �G���[�`�F�b�N����
void ErrorCheck() {    
    // �X�N���v�g�G���[�łȂ���΁A�Y��Entity���폜����
    CBaseEntity@ pTarget = null;  
    @pTarget = g_EntityFuncs.FindEntityByTargetname(pTarget, "wl_errchk");
    if (pTarget !is null) {
        g_EntityFuncs.Remove(pTarget);
    }
}

// �z�u�����_����
void ItemShuffle() {
    Vector angle = Vector(0,0,0);
    
    CBaseEntity@ pTarget = null;
    while ((@pTarget = g_EntityFuncs.FindEntityByClassname( pTarget, INFO_RANDWEAPON_NAME )) !is null) {
        
        CBaseEntity@ pEntity = g_EntityFuncs.Create( g_pcUtil.ChooseRandomWeapon(),  pTarget.GetOrigin(), angle, true);
        g_EntityFuncs.DispatchKeyValue(pEntity.edict(), "m_flCustomRespawnTime", 120.0);
        g_EntityFuncs.DispatchSpawn(pEntity.edict());
        
        g_EntityFuncs.Remove(pTarget);
    }

}

// �A�C�e������
void GrowItems() {    
    // medkit��armor
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

/** �v���C���[�Q���� */
HookReturnCode PlayerJoin( CBasePlayer@ pPlayer ) {
    
    if (!isFiredForScript) {
        ItemShuffle();
        ErrorCheck();
        GrowItems();
        isFiredForScript = true;
    }
    g_pcUtil.InitModel(pPlayer);
    return HOOK_CONTINUE;
}

/** �v���C���[Spawn�� */
HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer) {
    g_pcUtil.CheckStatus(pPlayer, true);
    
    g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_AUTO, g_sinSoundList[0], 1.0f, ATTN_NORM, 0, 100);
    
    int r = Math.RandomLong(0, 255);
    int g = Math.RandomLong(0, 255);
    int b = Math.RandomLong(0, 255);
    
    // �g��
    NetworkMessage messageWave(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
    messageWave.WriteByte(TE_BEAMCYLINDER);
    messageWave.WriteCoord(pPlayer.pev.origin.x);
    messageWave.WriteCoord(pPlayer.pev.origin.y);
    messageWave.WriteCoord(pPlayer.pev.origin.z);
    messageWave.WriteCoord(pPlayer.pev.origin.x);
    messageWave.WriteCoord(pPlayer.pev.origin.y);
    messageWave.WriteCoord(pPlayer.pev.origin.z + 100);
    messageWave.WriteShort(g_EngineFuncs.ModelIndex("sprites/laserbeam.spr"));
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

/** ���S�� */
HookReturnCode PlayerKilled (CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib) {
    g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_VOICE, g_sinSoundList[1], 1.0f, ATTN_NORM, 0, 100);
    return HOOK_CONTINUE;
}

// �^�C�}�[
void CheckTimer() {
    for (int i = 1; i <= g_Engine.maxClients; i++) {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if ( (pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive()) ) {
            pPlayer.GiveAmmo(3, UBOAPLAYERCLASS_AMMO_NAME, UBOAPLAYERCLASS_MAX_AMMO);
            
            g_pcUtil.CheckStatus(pPlayer, false);
        }
    }
}

// ---------------------------------------------------
// �����_������G���e�B�e�B
const string INFO_RANDWEAPON_NAME = "info_randomweapon";
class InfoRandomWeapon : ScriptBaseEntity {}
void RegisterInfoRandomWeapon() {
    g_CustomEntityFuncs.RegisterCustomEntity( "InfoRandomWeapon", INFO_RANDWEAPON_NAME );
}