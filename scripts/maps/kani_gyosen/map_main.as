/**
 * �I���D �}�b�v�X�N���v�g
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
    
    // �v���L���b�V��
    MAP_GIMMICK::Precache();
    
    RegisterBoat();
    RegisterBoatControl();
    
    // ����o�^
    RegisterHarpoon();
    RegisterAps();
    
    // ����^�C�}�[
    g_Scheduler.SetInterval("CheckTimer", 5.0);
    
    g_EngineFuncs.ServerPrint("[kani_gyosen] map scripts are working! ....(^^;)b\n");
}


//================================================
// �v���C���[�T�[�o�[�Q����
//================================================
HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer ) {
    MapInitCheck();
    
    return FUNC_VEHICLE::Fv_ClientPutInServer(pPlayer);
}

//================================================
// �v���C���[�ؒf��
//================================================
HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer) {
    
    return FUNC_VEHICLE::Fv_ClientDisconnect(pPlayer);
}

//================================================
// �v���C���[���S��
//================================================
HookReturnCode PlayerKilled (CBasePlayer@ pPlayer, CBaseEntity@ pEntity, int param) {
    
    return FUNC_VEHICLE::Fv_PlayerKilled(pPlayer, pEntity, param);
}

//================================================
// �v���C���[USE��
//================================================
HookReturnCode VehiclePlayerUse( CBasePlayer@ pPlayer, uint& out uiFlags ) {
        
    return FUNC_VEHICLE::Fv_VehiclePlayerUse(pPlayer, uiFlags);
}

//================================================
// �v���C���[�̒�����쏈���iPRE�j
//================================================
HookReturnCode VehiclePlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags ) {
    
    return FUNC_VEHICLE::Fv_VehiclePlayerPreThink(pPlayer, uiFlags);
}

//------------------------------------------------
// ����������������
//------------------------------------------------
void MapInitCheck() {
    
    if (!isFiredScript) {            
        // �X�N���v�g�G���[�łȂ���΁A�Y��Entity���폜����
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
// �^�C�}�[
//------------------------------------------------
void CheckTimer() {
    // �ċz�A�t���b�V�����C�g������
    for (int i = 1; i <= g_Engine.maxClients; i++) {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if ((pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive()) ) {
            pPlayer.pev.air_finished = g_Engine.time + 600;
            pPlayer.m_iFlashBattery = 100;
        }
    }
    
    // �J�j�ɂ���ւ����
    if ( Math.RandomLong( 0, 7 ) == 0) {
        ReplaceLeechToCrab();
    }
}

//------------------------------------------------
// �J�j����ւ�
//------------------------------------------------
void ReplaceLeechToCrab() {
    Vector pos;
    Vector ang;
    
    CBaseEntity@ pTarget = null;  
    while ((@pTarget = g_EntityFuncs.FindEntityByClassname(pTarget, "monster_babycrab")) !is null) {
        
        // �m���ł���ւ���
        if ( Math.RandomLong( 0, 9 ) == 0) {
            pos = pTarget.GetOrigin();
            ang = pTarget.pev.angles;
            
            // 㩔����i�W���܂�j
            string entName = pTarget.pev.targetname;
            entName.Replace("mon_", "plt_");
            g_EntityFuncs.FireTargets(entName, null, null, USE_OFF);
            
            // �a�폜
            g_EntityFuncs.Remove(pTarget);
            
            // �J�j�ǉ�
            CBaseEntity @pEntity = g_EntityFuncs.Create( "monster_headcrab",  pos, ang, true);
            g_EntityFuncs.DispatchKeyValue(pEntity.edict(), "displayname", "kani");
            g_EntityFuncs.DispatchKeyValue(pEntity.edict(), "health", "150");
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
        }
    }
    
}

