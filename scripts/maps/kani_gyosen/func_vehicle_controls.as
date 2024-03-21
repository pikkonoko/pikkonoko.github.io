/*
 * func_vehicle_controls
 *
 * 乗り物制御用ブラシ
 */
 
#include "func_vehicle_behavior"
#include "func_vehicle_boat"

// プレイヤーのユーザーデータのキー名。乗り物の情報を保存？
const string VEHICLE_RC_EHANDLE_KEY = "VEHICLE_RC_EHANDLE_KEY"; 

enum FuncVehicleControlsFlags {
    SF_VEHICLE_RC = 1 << 0, // リモートコントロールフラグ？ 1 でドライバーでなくリモート扱いとのこと
}

/**
 * コントロール（vehicle_control） クラス
 */
class VehicleControls : ScriptBaseEntity {
    
    private EHandle m_hVehicle;
    
    int ObjectCaps() {
        return ( BaseClass.ObjectCaps() & ~FCAP_ACROSS_TRANSITION ) | 
        ( self.pev.SpawnFlagBitSet( SF_VEHICLE_RC ) ? int( FCAP_IMPULSE_USE ) : 0 );
    }
    
    // デフォルトで動いてないらしいので、オーバーライドらしい。
    bool IsBSPModel() {
        return true;
    }
    
    void Spawn() {
        if( self.pev.SpawnFlagBitSet( SF_VEHICLE_RC ) )  {
            self.pev.solid = SOLID_BSP;
            self.pev.movetype = MOVETYPE_PUSH;
        } else {
            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;
        }
        
        g_EntityFuncs.SetModel( self, self.pev.model );

        g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        SetThink( ThinkFunction( Find ) );
        self.pev.nextthink = g_Engine.time;
    }
    
    void Find() {
        CBaseEntity@ pTarget = null;
        
        do {
            @pTarget = @g_EntityFuncs.FindEntityByTargetname(pTarget, self.pev.target);
        } while (pTarget !is null && !pTarget.pev.ClassNameIs( Boat::ENT_NAME ) );
        
        VehicleBoat@ ptrain = null;

        if( pTarget !is null ) {
            @ptrain = @FUNC_VEHICLE::VehicleBoatInstance( pTarget );
            
            // リモートでない場合にセットとのこと
            if( ptrain !is null && !self.pev.SpawnFlagBitSet( SF_VEHICLE_RC ) ) {
                ptrain.SetControls( self.pev );
            }
        } else {
            g_Game.AlertMessage( at_console, "No func_vehicle_boat %1\n", self.pev.target );
        }

        if( !self.pev.SpawnFlagBitSet( SF_VEHICLE_RC ) || ptrain is null ) {
            g_EntityFuncs.Remove( self );
        } else {
            m_hVehicle = pTarget;
        }
    }
    
    void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue ) {
        if( pActivator is null || !pActivator.IsPlayer() ) {
            return;
        }
            
        if( !m_hVehicle.IsValid() ) {
            g_EntityFuncs.Remove( self );
            return;
        }
            
        VehicleBoat@ ptrain = FUNC_VEHICLE::VehicleBoatInstance( m_hVehicle.GetEntity() );
        
        if( ptrain !is null ) {
            CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
        
            bool fisInControl = EHandle( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] ).IsValid();
            
            {
                CBasePlayer@ pDriver = ptrain.GetDriver();
                
                if( pDriver !is null ) {
                    FUNC_VEHICLE::TurnVehicleRCControlOff( pDriver );
                    
                    ptrain.SetDriver( null );
                }
            }
            
            
            if( !fisInControl ) {
                pPlayer.m_afPhysicsFlags |= PFLAG_ONTRAIN;
                pPlayer.m_iTrain = TrainSpeed(int(ptrain.self.pev.speed), ptrain.self.pev.impulse);
                pPlayer.m_iTrain |= TRAIN_NEW;
                
                CBaseEntity@ pDriver = ptrain.GetDriver();
                
                if( pDriver !is null ) {
                    CBasePlayer@ pPlayerDriver = cast<CBasePlayer@>( pDriver );
                    
                    if( pPlayerDriver !is null ) {
                        FUNC_VEHICLE::TurnVehicleRCControlOff( pPlayerDriver );
                    }
                }
                
                ptrain.SetDriver( pPlayer );
                pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] = m_hVehicle;
                
            }
        }
        else {
            g_EntityFuncs.Remove( self );
        }
    }
}
// 登録
void RegisterBoatControl() {
    g_CustomEntityFuncs.RegisterCustomEntity( "VehicleControls", Boat::CTRL_NAME );
}

