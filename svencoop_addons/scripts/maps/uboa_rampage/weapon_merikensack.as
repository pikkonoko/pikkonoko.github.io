/* 
* メリケンサック(Brass knuckle)
*/
#include "CKiaiAmmo"
#include "CRageEffect"
enum meriken_e {
    MERIKENSACK_FIDGET1 = 0,
    MERIKENSACK_FIDGET2,
    MERIKENSACK_FIDGET3,
    MERIKENSACK_IDLE1,
    MERIKENSACK_IDLE2,
    MERIKENSACK_IDLE3,
    MERIKENSACK_IDLE4,
    MERIKENSACK_DRAW,
    MERIKENSACK_L_PUNCH_1,
    MERIKENSACK_L_PUNCH_2,
    MERIKENSACK_L_PUNCH_3,
    MERIKENSACK_R_PUNCH_1,
    MERIKENSACK_R_PUNCH_2,
    MERIKENSACK_R_PUNCH_3
};

class weapon_merikensack : ScriptBasePlayerWeaponEntity {
    private CBasePlayer@ m_pPlayer = null;
    
    TraceResult m_trHit;
    
    int mRageLevel;
    float mRageTime;
    CRageEffect rageEffect;
    
    void Spawn() {
        self.Precache();
        rageEffect.Precache();
        
        g_EntityFuncs.SetModel( self, self.GetW_Model( "models/uboa_rampage/w_merikensack.mdl") );
        self.m_iDefaultAmmo = 20;
        self.m_flCustomDmg  = self.pev.dmg;
        
        mRageLevel = 0;
        mRageTime  = 0;
        
        self.FallInit();// get ready to fall down.
    }

    /** プリキャッシュ */
    void Precache() {
        self.PrecacheCustomModels();

        g_Game.PrecacheModel( "models/uboa_rampage/v_merikensack.mdl" );
        g_Game.PrecacheModel( "models/uboa_rampage/w_merikensack.mdl" );
        g_Game.PrecacheModel( "models/uboa_rampage/p_merikensack.mdl" );

        g_SoundSystem.PrecacheSound( "uboa_rampage/koraa.wav" );
        
        g_SoundSystem.PrecacheSound( "weapons/bullet_hit2.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod2.wav" );
        g_SoundSystem.PrecacheSound( "uboa_rampage/bishi.wav" );
        g_SoundSystem.PrecacheSound( "weapons/knife1.wav" );
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = UBOAKIAI_MAX_AMMO;
        info.iMaxAmmo2 = -1;
        info.iMaxClip  = WEAPON_NOCLIP;
        info.iSlot     = 1;
        info.iPosition = 5;
        info.iFlags    = 0;
        info.iWeight   = 10;
        return true;
    }    
    
    /** プレイヤーが武器を取得時 */
    bool AddToPlayer( CBasePlayer@ pPlayer ) {
        if (!BaseClass.AddToPlayer( pPlayer )) {
            return false;
        }
        @m_pPlayer = pPlayer;

        return true;
    }

    /** 武器取り出し時 */
    bool Deploy() {
        TurnOffRage();
        SetMinimumKiaiAmmo();
        
        return self.DefaultDeploy( self.GetV_Model( "models/uboa_rampage/v_merikensack.mdl" ),
            self.GetP_Model( "models/uboa_rampage/p_merikensack.mdl" ), MERIKENSACK_DRAW, "crowbar" );
    }

    /** 武器ホルスター時 */
    void Holster(int skiplocal) {
        self.m_fInReload = false;// cancel any reload in progress.
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5;
        
        TurnOffRage();
        SetMinimumKiaiAmmo();
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        Swing(0);
        WeaponIdle();
    }
    
    /** セカンダリアタック */
    void SecondaryAttack() {
        Swing(1);
        WeaponIdle();
    }
    /** サードアタック */
    void TertiaryAttack() {
        self.SendWeaponAnim( MERIKENSACK_FIDGET1 );
        self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
        
        TurnOnRage();
    }
    
    // RageモードON
    void TurnOnRage() {
        if (mRageLevel > 0) {
            return;
        }
        
        // 最大でないと発動しない
        if ((mRageLevel == 0) && (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType ) < UBOAKIAI_MAX_AMMO)) {
            return;
        }
        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 1);
        
        mRageTime = g_Engine.time + RAGE_ACTIVE_TIME;
        mRageLevel = rageEffect.TurnOnRage(m_pPlayer) + 3;
        
    }
    
    // RageモードOff
    void TurnOffRage() {
        rageEffect.TurnOffRage(m_pPlayer);
        
        mRageTime = 0;
        mRageLevel = 0;
    }
    
    void Smack() {
        g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
    }

    bool Swing( int armType ) {
        if ((self is null) || (m_pPlayer is null)) {
            return false;
        }
        
        bool fDidHit = false;

        TraceResult tr;

        Math.MakeVectors( m_pPlayer.pev.v_angle );
        Vector vecSrc    = m_pPlayer.GetGunPosition();
        Vector vecEnd    = vecSrc + g_Engine.v_forward * 60;
        
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

        if ( tr.flFraction >= 1.0 ) {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
            if ( tr.flFraction < 1.0 ) {
                // Calculate the point of intersection of the line (or hull) and the object we hit
                // This is and approximation of the "best" intersection
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if ((pHit is null) || (pHit.IsBSPModel()) ) {
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
                }
                vecEnd = tr.vecEndPos;    // This is the point on the actual surface (the hull could have hit space)
            }
        }
        // Rageモードと合わせてスピード、威力調整
        float dmgBuf = 8.0 + Math.RandomFloat(0.0, 6.0) + (0.5 * mRageLevel);
        float spdBuf = (mRageLevel > 0) ? 0.2 : 0.5;
        
        // アニメーション
        if (armType == 0) { 
            
            if (mRageLevel == 0) {
                self.SendWeaponAnim( MERIKENSACK_L_PUNCH_1 );
                self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
                self.m_flNextSecondaryAttack = g_Engine.time + spdBuf * 0.5;
            } else {
                self.SendWeaponAnim( MERIKENSACK_L_PUNCH_2 );
                self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
                self.m_flNextSecondaryAttack = g_Engine.time + spdBuf * 0.5;
            }
                
        } else {            
            if (mRageLevel == 0) {
                self.SendWeaponAnim( MERIKENSACK_R_PUNCH_1 );
                self.m_flNextPrimaryAttack = g_Engine.time + spdBuf * 0.5;
                self.m_flNextSecondaryAttack = g_Engine.time + spdBuf;
            } else {
                self.SendWeaponAnim( MERIKENSACK_R_PUNCH_2 );
                self.m_flNextPrimaryAttack = g_Engine.time + spdBuf * 0.5;
                self.m_flNextSecondaryAttack = g_Engine.time + spdBuf;
            }
        }
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
                
        // クリティカルヒット
        if (Math.RandomLong(0, 50) == 0) {
            g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_VOICE, "uboa_rampage/koraa.wav", 1.0f, ATTN_NONE, 0, Math.RandomLong( 100, 150 ));
            dmgBuf *= 2;
        }
    
        // 空振り
        if ( tr.flFraction >= 1.0 ) {
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
            
        // ヒット
        } else {
            fDidHit = true;
            
            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
            

            g_WeaponFuncs.ClearMultiDamage();
            pEntity.TraceAttack( m_pPlayer.pev, dmgBuf, g_Engine.v_forward, tr, DMG_CLUB ); 
            g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

            // play thwack, smack, or dong sound
            float flVol = 1.0;
            bool fHitWorld = true;

            // プレイヤーやNPCにヒット時
            if( pEntity !is null ) {
                if (pEntity.Classify() != CLASS_NONE) {
                    
                    // 少し押し出す
                    pEntity.pev.velocity = pEntity.pev.velocity - ( self.pev.origin - pEntity.pev.origin ).Normalize() * 100;
                    
                    // 気合増加
                    if ((mRageLevel == 0) && (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < UBOAKIAI_MAX_AMMO)) {
                        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + Math.RandomLong(1, 3));
                        
                        if (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) >= UBOAKIAI_MAX_AMMO) {
                            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, UBOAKIAI_MAX_AMMO);
                            rageEffect.ReadyEffect(m_pPlayer);
                        }
                    }
                    
                    g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_WEAPON, "uboa_rampage/bishi.wav", 1.0f, ATTN_NONE, 0, Math.RandomLong( 90, 110 ));
                    
                    
                    m_pPlayer.m_iWeaponVolume = 128; 
                    if( !pEntity.IsAlive() )
                        return true;
                    else
                        flVol = 0.1;

                    fHitWorld = false;
                }
            }

            // 壁殴り時
            if( fHitWorld == true ) {
                float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
                
                // override the volume here, cause we don't play texture sounds in multiplayer, 
                // and fvolbar is going to be 0 from the above call.

                fvolbar = 1;

                // also play crowbar strike
                switch( Math.RandomLong( 0, 1 ) )
                {
                case 0:
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/bullet_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
                    break;
                case 1:
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cbar_hitbod2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
                    break;
                }
            }

            // delay the decal a bit
            m_trHit = tr;
            SetThink( ThinkFunction( this.Smack ) );
            self.pev.nextthink = g_Engine.time + 0.2;

            m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
        }
        return fDidHit;
    }
    
    
    void WeaponIdle() {
        if ((mRageTime > 0) && (g_Engine.time >= mRageTime)) {
            TurnOffRage();
        }
    }
    
    /** 気合の最低値セット */
    void SetMinimumKiaiAmmo() {
        // 気合がなければ1に
        if (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType ) < 1) {
            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 1);
        }
    }
    
}

string GetMerikenSackName() {
    return "weapon_merikensack";
}

void RegisterMerikenSack() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_merikensack", GetMerikenSackName() );
    g_ItemRegistry.RegisterWeapon( GetMerikenSackName(), "uboa_rampage", UBOAKIAI_AMMO_NAME);
}
