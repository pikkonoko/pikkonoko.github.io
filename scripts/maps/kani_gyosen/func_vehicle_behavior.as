/**
 *
 *  func_vehicle �̋����Ǘ�
 *
 */
#include "func_vehicle_boat"

namespace FUNC_VEHICLE {

    //================================================
    // �v���C���[�T�[�o�[�Q����
    //================================================
    HookReturnCode Fv_ClientPutInServer( CBasePlayer@ pPlayer ) {
        dictionary@ userData = pPlayer.GetUserData();
        userData.set( VEHICLE_RC_EHANDLE_KEY, EHandle() );
        
        
        return HOOK_CONTINUE;
    }

    //================================================
    // �v���C���[�ؒf��
    //================================================
    HookReturnCode Fv_ClientDisconnect(CBasePlayer@ pPlayer) {
        // �^�]���[�h���������Ă���
        TurnOffPlayerDrive(pPlayer);
        
        return HOOK_CONTINUE;
    }

    //================================================
    // �v���C���[���S��
    //================================================
    HookReturnCode Fv_PlayerKilled (CBasePlayer@ pPlayer, CBaseEntity@ pEntity, int param) {
        // �^�]���[�h���������Ă���
        TurnOffPlayerDrive(pPlayer);
        
        return HOOK_CONTINUE;
    }

    //================================================
    // �v���C���[USE��
    //================================================
    HookReturnCode Fv_VehiclePlayerUse( CBasePlayer@ pPlayer, uint& out uiFlags ) {
        if ( ( pPlayer.m_afButtonPressed & IN_USE ) != 0 ) {
            if( EHandle( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] ).IsValid() ) {
                uiFlags |= PlrHook_SkipUse;
                
                TurnVehicleRCControlOff( pPlayer );
                return HOOK_CONTINUE;
            }
            
            if ( !pPlayer.m_hTank.IsValid() ) {
                if ( ( pPlayer.m_afPhysicsFlags & PFLAG_ONTRAIN ) != 0 ) {
                    TurnOffPlayerDrive(pPlayer);
                    
                    CBaseEntity@ pTrain = g_EntityFuncs.Instance( pPlayer.pev.groundentity );

                    // USE�L�[�����ŁA�^�]����߂�
                    if( pTrain !is null ) {
                        VehicleBoat@ pVehicle = cast<VehicleBoat@>( CastToScriptClass( pTrain ) );
                        
                        if( pVehicle !is null ) {
                            pVehicle.SetDriver( null );    
                        }
                    }
                    uiFlags |= PlrHook_SkipUse;
                    
                    return HOOK_CONTINUE;
                    
                // ��蕨�̃R���g���[���J�n
                } else {
                    CBaseEntity@ pTrain = g_EntityFuncs.Instance( pPlayer.pev.groundentity );
                    
                    if ( pTrain !is null
                        && (pPlayer.pev.button & IN_JUMP) == 0
                        && pPlayer.pev.FlagBitSet( FL_ONGROUND )
                        && (pTrain.ObjectCaps() & FCAP_DIRECTIONAL_USE) != 0
                        && pTrain.OnControls(pPlayer.pev)
                    ) {
                        pPlayer.m_iTrain = TrainSpeed(int(pTrain.pev.speed), pTrain.pev.impulse);
                        TurnOnPlayerDrive(pPlayer);

                        // ��蕨�̉^�]�J�n
                        VehicleBoat@ pVehicle = cast<VehicleBoat@>( CastToScriptClass( pTrain ) );
                            
                        if( pVehicle !is null ) {
                            pVehicle.SetDriver( pPlayer );
                        }
                            
                        uiFlags |= PlrHook_SkipUse;
                        return HOOK_CONTINUE;
                    }
                }
            }
        }
        
        return HOOK_CONTINUE;
    }

    //================================================
    // �v���C���[�̒�����쏈���iPRE�j
    //================================================
    HookReturnCode Fv_VehiclePlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags ) {
        CBaseEntity@ pTrain = null;
        
        bool fUsingRC = EHandle( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] ).IsValid();    
        if ( ( pPlayer.m_afPhysicsFlags & PFLAG_ONTRAIN ) != 0 || fUsingRC ) {
            pPlayer.pev.flags |= FL_ONTRAIN;
        
            @pTrain = @g_EntityFuncs.Instance( pPlayer.pev.groundentity );
            
            if ( pTrain is null ) {
                TraceResult trainTrace;
                // Maybe this is on the other side of a level transition
                g_Utility.TraceLine( pPlayer.pev.origin, pPlayer.pev.origin + Vector(0,0,-38), ignore_monsters, pPlayer.edict(), trainTrace );

                // HACKHACK - Just look for the func_tracktrain classname
                if ( trainTrace.flFraction != 1.0 && trainTrace.pHit !is null )
                    @pTrain = @g_EntityFuncs.Instance( trainTrace.pHit );

                if ( pTrain is null 
                    || (pTrain.ObjectCaps() & FCAP_DIRECTIONAL_USE) == 0 
                    || !pTrain.OnControls(pPlayer.pev) 
                ) {
                    TurnOffPlayerDrive(pPlayer);

                    //Set driver to NULL if we stop driving the vehicle
                    if( pTrain !is null ) {
                        VehicleBoat@ pVehicle = cast<VehicleBoat@>( CastToScriptClass( pTrain ) );
                        
                        if( pVehicle !is null ) {
                            pVehicle.SetDriver( null );
                        }
                    }
                    
                    uiFlags |= PlrHook_SkipVehicles;
                    return HOOK_CONTINUE;
                }
                
            } else if ( HandlePlayerInAir( pPlayer, pTrain ) )  {
                uiFlags |= PlrHook_SkipVehicles;
                return HOOK_CONTINUE;
            }

            //Check if it's a func_vehicle - Solokiller 2014-10-24
            if( fUsingRC ) {
                @pTrain = EHandle(pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ]).GetEntity();
                
                //fContinue = false;
            }
            
            if( pTrain is null ) {
                return HOOK_CONTINUE;
            }
                
            VehicleBoat@ pVehicle = cast<VehicleBoat@>( CastToScriptClass( pTrain ) );
            if( pVehicle is null ) {
                return HOOK_CONTINUE;
            }
            
            // �L�[���͓ǂݎ��
            pVehicle.AnalysisInput(pPlayer, pTrain);
            
        } else {
            pPlayer.pev.flags &= ~FL_ONTRAIN;
        }
        
        return HOOK_CONTINUE;
    }

    //-----------------------------------------
    // �v���C���[���󒆂ɂ���ꍇ�̏���
    //-----------------------------------------
    bool HandlePlayerInAir( CBasePlayer@ pPlayer, CBaseEntity@ pTrain ) {
        if ( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) ) {
            // �W�����v�A�X�g���C�t�A�R���g���[���������ɂȂ����ۂɉ^�]���[�h���~
            TurnOffPlayerDrive(pPlayer);

            // �~�܂����ꍇ�ɉ^�]�҂̐ݒ��NULL��
            if( pTrain !is null ) {
                VehicleBoat@ pVehicle = VehicleBoatInstance( pTrain ) ;
                
                if( pVehicle !is null ) {
                    pVehicle.SetDriver( null );
                }
            }
            
            if( EHandle( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] ).IsValid() ) {
                TurnVehicleRCControlOff( pPlayer );
            }        
            return true;
        }
        return false;
    }



    //--------------------------------------------------
    // Vehicle�C���X�^���X�L���X�g�ϊ�����
    //--------------------------------------------------
    VehicleBoat@ VehicleBoatInstance( CBaseEntity@ pEntity ) {
        if (pEntity.pev.ClassNameIs( "func_vehicle_boat" ) ) {
            return cast<VehicleBoat@>( CastToScriptClass( pEntity ) );
        }
        return null;
    }

    //--------------------------------------------------
    // �R���g���[���G���e�B�e�B���~����
    //--------------------------------------------------
    void TurnVehicleRCControlOff( CBasePlayer@ pPlayer ) {
        EHandle train = EHandle( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] );
                    
        if( train.IsValid() ) {
            VehicleBoat@ pVehicle = VehicleBoatInstance( train.GetEntity() );
            
            if( pVehicle !is null ) {
                pVehicle.SetDriver( null );
            }
        }
                
        pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] = EHandle();
        TurnOffPlayerDrive(pPlayer);
    }

    //--------------------------------------------------
    // �v���C���[�̉^�]���[�h�J�n�i�����햳����Ԃցj
    //--------------------------------------------------
    void TurnOnPlayerDrive(CBasePlayer@ pPlayer) {
        if (@pPlayer is null) {
            return;
        }
        
        pPlayer.m_afPhysicsFlags |= PFLAG_ONTRAIN;
        pPlayer.m_iTrain         |= TRAIN_NEW;
        
        //pPlayer.m_iEffectInvulnerable = 1;
        //pPlayer.m_iEffectInvisible    = 1;
        //pPlayer.m_iEffectNonSolid     = 1;
        pPlayer.m_iEffectBlockWeapons = 1;
        pPlayer.m_flEffectSpeed       = 0;
        pPlayer.ApplyEffects();
    }

    //--------------------------------------------------
    // �v���C���[�^�]���[�h���~�i������L����Ԃցj
    //--------------------------------------------------
    void TurnOffPlayerDrive(CBasePlayer@ pPlayer) {
        if (@pPlayer is null) {
            return;
        }
        
        pPlayer.m_afPhysicsFlags &= ~PFLAG_ONTRAIN;
        pPlayer.m_iTrain          =  TRAIN_NEW | TRAIN_OFF;
        
        //pPlayer.m_iEffectInvulnerable = 0;
        //pPlayer.m_iEffectInvisible    = 0;
        //pPlayer.m_iEffectNonSolid     = 0;
        pPlayer.m_iEffectBlockWeapons = 0;
        pPlayer.m_flEffectSpeed       = 1.0;
        pPlayer.ApplyEffects();
    }
}

