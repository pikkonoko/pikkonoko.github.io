/**
 *
 *  func_vehicle の挙動管理
 *
 */
#include "func_vehicle_boat"

namespace FUNC_VEHICLE {

    //================================================
    // プレイヤーサーバー参加時
    //================================================
    HookReturnCode Fv_ClientPutInServer( CBasePlayer@ pPlayer ) {
        dictionary@ userData = pPlayer.GetUserData();
        userData.set( VEHICLE_RC_EHANDLE_KEY, EHandle() );
        
        
        return HOOK_CONTINUE;
    }

    //================================================
    // プレイヤー切断時
    //================================================
    HookReturnCode Fv_ClientDisconnect(CBasePlayer@ pPlayer) {
        // 運転モードを解除しておく
        TurnOffPlayerDrive(pPlayer);
        
        return HOOK_CONTINUE;
    }

    //================================================
    // プレイヤー死亡時
    //================================================
    HookReturnCode Fv_PlayerKilled (CBasePlayer@ pPlayer, CBaseEntity@ pEntity, int param) {
        // 運転モードを解除しておく
        TurnOffPlayerDrive(pPlayer);
        
        return HOOK_CONTINUE;
    }

    //================================================
    // プレイヤーUSE時
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

                    // USEキー押下で、運転をやめる
                    if( pTrain !is null ) {
                        VehicleBoat@ pVehicle = cast<VehicleBoat@>( CastToScriptClass( pTrain ) );
                        
                        if( pVehicle !is null ) {
                            pVehicle.SetDriver( null );    
                        }
                    }
                    uiFlags |= PlrHook_SkipUse;
                    
                    return HOOK_CONTINUE;
                    
                // 乗り物のコントロール開始
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

                        // 乗り物の運転開始
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
    // プレイヤーの定期動作処理（PRE）
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
            
            // キー入力読み取り
            pVehicle.AnalysisInput(pPlayer, pTrain);
            
        } else {
            pPlayer.pev.flags &= ~FL_ONTRAIN;
        }
        
        return HOOK_CONTINUE;
    }

    //-----------------------------------------
    // プレイヤーが空中にいる場合の処理
    //-----------------------------------------
    bool HandlePlayerInAir( CBasePlayer@ pPlayer, CBaseEntity@ pTrain ) {
        if ( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) ) {
            // ジャンプ、ストライフ、コントロールが無効になった際に運転モード中止
            TurnOffPlayerDrive(pPlayer);

            // 止まった場合に運転者の設定をNULLへ
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
    // Vehicleインスタンスキャスト変換処理
    //--------------------------------------------------
    VehicleBoat@ VehicleBoatInstance( CBaseEntity@ pEntity ) {
        if (pEntity.pev.ClassNameIs( "func_vehicle_boat" ) ) {
            return cast<VehicleBoat@>( CastToScriptClass( pEntity ) );
        }
        return null;
    }

    //--------------------------------------------------
    // コントロールエンティティ中止処理
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
    // プレイヤーの運転モード開始（→武器無効状態へ）
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
    // プレイヤー運転モード中止（→武器有効状態へ）
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

