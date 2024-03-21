/* 
 * 武器基本クラス
 */
#include "CKiaiAmmo"
#include "CRageEffect"
enum uboamelee_e {
	UBOAMELEE_IDLE1 = 0,
    UBOAMELEE_IDLE2,
	UBOAMELEE_IDLE3,
	UBOAMELEE_DRAW,
	UBOAMELEE_TAUNT1,
	UBOAMELEE_TAUNT2,
	UBOAMELEE_SWING1_1,
	UBOAMELEE_SWING1_2,
	UBOAMELEE_SWING1_3,
	UBOAMELEE_SWING2_1,
	UBOAMELEE_SWING2_2,
	UBOAMELEE_SWING2_3,
	UBOAMELEE_POWERATTACK_1,
	UBOAMELEE_POWERATTACK_2,
	UBOAMELEE_POWERATTACK_3
};

const string MODEL_PATH_DIR = "models/uboa_rampage/";  // モデルDIR
const int MAX_CARRY_NUM = 2;                           // 武器最大所持可能数
const string DURABILITY_AMMO_NAME = "ammo_durability"; // 耐久力Ammo名
const int UBOAMELEE_MAX_AMMO    = 200;                 // 耐久力Ammoの最大設定値

// 武器ごとの耐久力
const int SHINAI_MAX_AMMO       = 130;
const int BOKUTOU_MAX_AMMO      = 140;
const int BAT_MAX_AMMO          = 150;
const int METALBAT_MAX_AMMO     = 170;
const int NAILBAT_MAX_AMMO      = 110;
const int KAKUZAI_MAX_AMMO      = 110;
const int IRONPIPE_MAX_AMMO     = 160;
const int BRUSH_MAX_AMMO        = 110;
const int SHOVEL_MAX_AMMO       = 160;
const int FRYINGPAN_MAX_AMMO    = 150;
const int MONKEYWRENCH_MAX_AMMO = 130;
const int HOCKEYSTICK_MAX_AMMO  = 110;
const int TENNISRACKET_MAX_AMMO = 100;
const int GOLDBAR_MAX_AMMO      = 200;
const int PLATINUMBAR_MAX_AMMO  = 200;

/** 武器基本クラス（仮想） */
abstract class weapon_uboamelee : ScriptBasePlayerWeaponEntity {
    protected CBasePlayer@ m_pPlayer = null;
    
    string vmodel;
    string pmodel;
    string wmodel;
    int mBody;
    string wepStatus;
    float wepReach;
    
    protected int mBreakCnt;        // 破壊時カウンター
    protected float mNonBreakTime;
    
    int durability;
        
    int mRageLevel;
    float mRageTime;
    CRageEffect rageEffect;
    
    /** 初期化処理（Spawnオーバーライドできなかったので） */
    protected void Init(string &in baseName) {
        this.mBody = 0;
        this.vmodel = MODEL_PATH_DIR + "v_" + baseName + ".mdl";
        this.pmodel = MODEL_PATH_DIR + "p_" + baseName + ".mdl";
        this.wmodel = MODEL_PATH_DIR + "w_" + baseName + ".mdl";
        
        // 武器ごと設定
        SetStatusByName(baseName);
        
		self.Precache();
	    rageEffect.Precache();
        
		g_EntityFuncs.SetModel(self, self.GetW_Model(this.wmodel));
		self.m_flCustomDmg = self.pev.dmg;
        self.m_iSecondaryAmmoType = 0;
        //self.m_iDefaultAmmo = 1;
        
	    mRageLevel = 0;
        mRageTime = 0;

		self.FallInit();// get ready to fall down.
        
	    // wモデルを光らせる
        self.pev.renderfx    = kRenderFxGlowShell;
        self.pev.renderamt   = 4;
        self.pev.rendercolor = Vector(64, 64, 64);
        
    }
    
    /** 武器の状態を設定 */
    private void SetStatusByName(string &in baseName) {
        this.wepReach = 85.0;
        string wepInfo = "";
        if (baseName == "shinai") {
            wepInfo += "[Bamboo sword]\n";
            wepInfo += "Power      : >>>\n";
            wepInfo += "Speed      : >>>>\n";
            wepInfo += "Reach      : >>>\n";
            wepInfo += "Durability : >>>\n";
            durability = SHINAI_MAX_AMMO;
        } else if (baseName == "bokutou") {
            wepInfo += "[Wood sword]\n";
            wepInfo += "Power      : >>>\n";
            wepInfo += "Speed      : >>>>\n";
            wepInfo += "Reach      : >>>\n";
            wepInfo += "Durability : >>>\n";
            durability = BOKUTOU_MAX_AMMO;
        } else if (baseName == "bat") {
            wepInfo += "[Baseball bat]\n";
            wepInfo += "Power      : >>>>\n";
            wepInfo += "Speed      : >>>\n";
            wepInfo += "Reach      : >>>\n";
            wepInfo += "Durability : >>>\n";
            durability = BAT_MAX_AMMO;
        } else if (baseName == "metalbat") {
            wepInfo += "[Metal bat]\n";
            wepInfo += "Power      : >>>>\n";
            wepInfo += "Speed      : >>\n";
            wepInfo += "Reach      : >>>\n";
            wepInfo += "Durability : >>>>>\n";
            durability = METALBAT_MAX_AMMO;
        } else if (baseName == "nailbat") {
            wepInfo += "[Nailed bat]\n";
            wepInfo += "Power      : >>>>>\n";
            wepInfo += "Speed      : >>>\n";
            wepInfo += "Reach      : >>>\n";
            wepInfo += "Durability : >>\n";
            durability = NAILBAT_MAX_AMMO;
        } else if (baseName == "kakuzai") {
            wepInfo += "[Squared timber]\n";
            wepInfo += "Power      : >>\n";
            wepInfo += "Speed      : >>>>\n";
            wepInfo += "Reach      : >>\n";
            wepInfo += "Durability : >>\n";
            durability = KAKUZAI_MAX_AMMO;
            this.wepReach = 80.0;
        } else if (baseName == "brush") {
            wepInfo += "[Deck brush]\n";
            wepInfo += "Power      : >>>\n";
            wepInfo += "Speed      : >>>\n";
            wepInfo += "Reach      : >>>>>\n";
            wepInfo += "Durability : >>\n";
            durability = BRUSH_MAX_AMMO;
            this.wepReach = 95.0;
        } else if (baseName == "ironpipe") {
            wepInfo += "[Iron pipe]\n";
            wepInfo += "Power      : >>>>\n";
            wepInfo += "Speed      : >>\n";
            wepInfo += "Reach      : >>\n";
            wepInfo += "Durability : >>>>\n";
            durability = IRONPIPE_MAX_AMMO;
            this.wepReach = 80.0;
        } else if (baseName == "shovel") {
            wepInfo += "[Shovel]\n";
            wepInfo += "Power      : >>>>\n";
            wepInfo += "Speed      : >\n";
            wepInfo += "Reach      : >>>>\n";
            wepInfo += "Durability : >>>>\n";
            durability = SHOVEL_MAX_AMMO;
            this.wepReach = 90.0;
        } else if (baseName == "fryingpan") {
            wepInfo += "[Frying pan]\n";
            wepInfo += "Power      : >>>\n";
            wepInfo += "Speed      : >>\n";
            wepInfo += "Reach      : >\n";
            wepInfo += "Durability : >>>>\n";
            durability = FRYINGPAN_MAX_AMMO;
            this.wepReach = 75.0;
        } else if (baseName == "monkeywrench") {
            wepInfo += "[Monkey wrench]\n";
            wepInfo += "Power      : >>\n";
            wepInfo += "Speed      : >>>>\n";
            wepInfo += "Reach      : >\n";
            wepInfo += "Durability : >>>\n";
            durability = MONKEYWRENCH_MAX_AMMO;
            this.wepReach = 75.0;
        } else if (baseName == "hockeystick") {
            wepInfo += "[Hockey stick]\n";
            wepInfo += "Power      : >>>\n";
            wepInfo += "Speed      : >>>>\n";
            wepInfo += "Reach      : >>>>>\n";
            wepInfo += "Durability : >>\n";
            durability = HOCKEYSTICK_MAX_AMMO;
            this.wepReach = 95.0;
        } else if (baseName == "tennisracket") {
            wepInfo += "[Tennis racket]\n";
            wepInfo += "Power      : >\n";
            wepInfo += "Speed      : >>>>>\n";
            wepInfo += "Reach      : >>\n";
            wepInfo += "Durability : >\n";
            durability = TENNISRACKET_MAX_AMMO;
            this.wepReach = 80.0;
        } else if (baseName == "goldbar") {
            wepInfo += "[Gold Ingot]\n";
            wepInfo += "Power      : >>>>>\n";
            wepInfo += "Speed      : >>>>>\n";
            wepInfo += "Reach      : >\n";
            wepInfo += "Durability : >>>>>\n";
            durability = GOLDBAR_MAX_AMMO;
            this.wepReach = 75.0;
        } else if (baseName == "platinumbar") {
            wepInfo += "[Platinum ingot]\n";
            wepInfo += "Power      : >>>>>\n";
            wepInfo += "Speed      : >>>>>\n";
            wepInfo += "Reach      : >\n";
            wepInfo += "Durability : >>>>>\n";
            durability = PLATINUMBAR_MAX_AMMO;
            this.wepReach = 75.0;
        }
        
        this.wepStatus = wepInfo;
    }

    /** プリキャッシュ処理 */
	void Precache() {
		self.PrecacheCustomModels();

		g_Game.PrecacheModel(this.vmodel);
		g_Game.PrecacheModel(this.pmodel);
		g_Game.PrecacheModel(this.wmodel);
	    
	    g_Game.PrecacheModel("models/mbarrel.mdl");
	    
	    g_SoundSystem.PrecacheSound( "uboa_rampage/koraa.wav" );

		g_SoundSystem.PrecacheSound( "weapons/bullet_hit2.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "uboa_rampage/bishi.wav" );
		g_SoundSystem.PrecacheSound( "uboa_rampage/doka.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cbar_miss1.wav" );
	    
		g_SoundSystem.PrecacheSound( "ambience/wood2.wav" );
	}
    
    /** 所有制限 */
    private bool HasMeleeWeapon(CBasePlayer@ pPlayer) {
        const string[] weaponsName = {
            "weapon_bat",
            "weapon_metalbat",
            "weapon_nailbat",
            "weapon_kakuzai",
            "weapon_bokutou",
            "weapon_shinai",
            "weapon_fryingpan",
            "weapon_brush",
            "weapon_shovel",
            "weapon_ironpipe",
            "weapon_monkeywrench",
            "weapon_hockeystick",
            "weapon_tennisracket",
            "weapon_goldbar",
            "weapon_platinumbar"
        };
        int carryCount = 0;
        for (uint i = 0; i < weaponsName.length(); i++) {    
            if (pPlayer.HasNamedPlayerItem(weaponsName[i]) !is null) {
                carryCount++;
                if (carryCount >= MAX_CARRY_NUM) {
                    return true;
                }
            }
        }
        return false;
    }
    
    /** プレイヤーへの武器追加 */
    bool AddToPlayer(CBasePlayer@ pPlayer) {
        if (!HasMeleeWeapon(pPlayer)) {
            if( BaseClass.AddToPlayer(pPlayer) ) {
                @m_pPlayer = pPlayer;
                
                NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
                message.WriteLong( self.m_iId );
                message.End();
                
                SetMinimumKiaiAmmo();
                return true;
            }
        }
        return false;
    }
    
    /** 武器取り出し */
    bool Deploy() {
	    self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
	    self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
        
        this.mBreakCnt      = 0;
        this.mNonBreakTime  = g_Engine.time;
        
        // HUDへ反映
        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, durability);
        
        TurnOffRage();
        SetMinimumKiaiAmmo();
        
        HUDTextParams textParms;
        textParms.fxTime = 30;
        textParms.fadeinTime = 0.5;
        textParms.holdTime = 3.0;
        textParms.fadeoutTime = 1.0;
        textParms.effect = 0;
        textParms.channel = 2;
        textParms.x = 0.05;
        textParms.y = 0.40;
        textParms.r1 = 0;
        textParms.g1 = 255;
        textParms.b1 = 255;
        textParms.r2 = 0;
        textParms.g2 = 0;
        textParms.b2 = 255;
        g_PlayerFuncs.HudMessage(m_pPlayer, textParms, this.wepStatus);

        return self.DefaultDeploy(self.GetV_Model(this.vmodel), self.GetP_Model(this.pmodel),
            UBOAMELEE_DRAW, "crowbar", 0, mBody);
    }

    /** 武器しまう */
	void Holster(int skiplocal) {
		self.m_fInReload = false;// cancel any reload in progress.
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5;
	    
	    TurnOffRage();
        SetMinimumKiaiAmmo();
	}

    /** 攻撃 */
	protected bool Swing( int attackType ) {
	    
	    if ((self is null) || (m_pPlayer is null)) {
	        return false;
	    }
	    
	    
	    // 壊れてるなら攻撃できない
	    if (durability <= 0) {
	        return false;
	    }
	    
		bool fDidHit = false;
		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * this.wepReach;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 ) {
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 ) {
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			    if ((pHit is null) || (pHit.IsBSPModel()) ) {
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
			    }
				vecEnd = tr.vecEndPos;
			}
		}
	    
	    
	    // ダメージ
		float flDamage = 10;
	    if ( self.m_flCustomDmg > 0 ) {
			flDamage = self.m_flCustomDmg;
	    }
	    
	    // クリティカルヒット
	    if (Math.RandomLong(0, 40) == 0) {
            g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_VOICE, "uboa_rampage/koraa.wav", 1.0f, ATTN_NONE, 0, Math.RandomLong( 100, 150 ));
	        flDamage *= 2;
	    }
	    
        // 空振り
	    if ( tr.flFraction >= 1.0 ) {
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cbar_miss1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
	        
		// ヒット
		} else {
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

		    
			g_WeaponFuncs.ClearMultiDamage();
		    pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB ); 
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null ) {

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED ) {
				    // 少し押し出す
				    float nockBack = (attackType == 0) ? 100.0 : 300.0;
				    pEntity.pev.velocity = pEntity.pev.velocity - ( self.pev.origin - pEntity.pev.origin ).Normalize() * nockBack;
				    
				    string hitSound = (attackType == 0) ? "uboa_rampage/bishi.wav" : "uboa_rampage/doka.wav";
				    g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_WEAPON, hitSound, 1.0f, ATTN_NONE, 0, Math.RandomLong( 90, 110 ));
				    
				    // 気合増加
				    if ((mRageLevel == 0) && (m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) < UBOAKIAI_MAX_AMMO)) {
                        m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) + Math.RandomLong(1, 3));
				        
				        if (m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) >= UBOAKIAI_MAX_AMMO) {
				            m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, UBOAKIAI_MAX_AMMO);
				            rageEffect.ReadyEffect(m_pPlayer);
				        }
				    }
				    
				   
					m_pPlayer.m_iWeaponVolume = 128; 
				    if( !pEntity.IsAlive() ) {
						return true;
				    } else {
						flVol = 0.1;
				    }

					fHitWorld = false;
				}
			}

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
		    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CROWBAR );

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
	    
	    // 耐久力減
	    if (fDidHit) {
	        ReduceDurability();
	    }  
		return fDidHit;
	}
    
    /** リロード */
    void Reload() {
        // しゃがみリロードで破壊
        if( (( m_pPlayer.pev.button & IN_DUCK ) != 0) && ( g_Engine.time >= this.mNonBreakTime + 1.0) ) {
            g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "[DESTROYING WEAPON]");
            
            // 破壊音
            if (this.mBreakCnt == 0) {
                g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_WEAPON, "ambience/wood2.wav", 1.0f, ATTN_NONE, 0, Math.RandomLong( 90, 110 ));
                self.SendWeaponAnim( UBOAMELEE_TAUNT1 ,0 ,0);
            }
            this.mBreakCnt += 1;
            if (this.mBreakCnt > 30) {
                this.mBreakCnt = 0;
                ReduceDurability(10);
            }
            
        // 通常表示処理
        } else {
            Deploy();
        }
    }    
    
    /** 耐久力減少 */
    protected void ReduceDurability() {
        ReduceDurability(Math.RandomLong(0, 2));
    }
    
    protected void ReduceDurability(int val) {
        durability -= val;
        durability = (durability < 0) ? 0 : durability;
        
        // HUD反映
        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, durability);
        
	    // 壊れてるなら武器解除
	    if (durability <= 0) {
	        BrokenEffect();
            g_EntityFuncs.Remove( self ); 
	    }
    }
    
    /** RageモードON */
    protected void TurnOnRage(CBasePlayer@ pPlayer) {
        // 壊れてなくて、気合最大でないと発動しない
        if ((mRageLevel > 0) 
            || (durability <= 0)
            || (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType ) < UBOAKIAI_MAX_AMMO)) {
            return;
        }
        m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, 1);
        
        mRageTime = g_Engine.time + RAGE_ACTIVE_TIME;
        mRageLevel = rageEffect.TurnOnRage(m_pPlayer) + 3;
    }
    
    /** RageモードOff */
    protected void TurnOffRage() {
        rageEffect.TurnOffRage(m_pPlayer);
        
        mRageTime = 0;
        mRageLevel = 0;
    }
    
    /** アイドル状態 */
    void WeaponIdle() {
        if ((mRageTime > 0) && (g_Engine.time > mRageTime)) {
            TurnOffRage();
        }
        
        // HUDへ反映
        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, durability);
    }
    
    /** 気合の最低値セット */
    void SetMinimumKiaiAmmo() {
        // 気合がなければ1に
        if (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType ) < 1) {
            m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, 1);
        }
    }
    
    /** 武器破損時エフェクト */
    protected void BrokenEffect() {
        g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_WEAPON, "ambience/wood2.wav", 1.0f, ATTN_NONE, 0, Math.RandomLong( 90, 110 ));
        g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "WEAPON BROKEN!!\n");
        
        NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        m.WriteByte(TE_EXPLODEMODEL);
        m.WriteCoord(m_pPlayer.pev.origin.x);
        m.WriteCoord(m_pPlayer.pev.origin.y);
        m.WriteCoord(m_pPlayer.pev.origin.z);
        m.WriteCoord(300);     // velocity
        m.WriteShort(g_EngineFuncs.ModelIndex("models/mbarrel.mdl"));
        m.WriteShort(12);    // count
        m.WriteByte(30);  // life
        m.End();
    }
    
}

// ---- 耐久力 --------------------------
class DurabilityAmmo : ScriptBasePlayerAmmoEntity {
	void Spawn() {
		g_Game.PrecacheModel( "models/w_9mmclip.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	    
		g_EntityFuncs.SetModel( self, "models/w_9mmclip.mdl" );
		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pither ) {
		return false;
	}
    
}

void RegisterDurabilityAmmo() {
	g_CustomEntityFuncs.RegisterCustomEntity( "DurabilityAmmo", DURABILITY_AMMO_NAME );
}