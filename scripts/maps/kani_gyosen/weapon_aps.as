/*  
 * APS水中銃
 */

namespace WEP_APS {
    const string WEP_NAME   = "weapon_aps";
    const string TPV_M_TYPE = "mp5";
    
    enum motion_e {
        MOTION_LONGIDLE = 0,
        MOTION_IDLE,
        MOTION_RELOAD,
        MOTION_RELOAD_EMPTY,
        MOTION_DEPLOY,
        MOTION_FIRE,
        MOTION_ADS_ON,
        MOTION_ADS,
        MOTION_ADS_OFF,
        MOTION_ADS_FIRE
    };

    const int MAX_AMMO      = 600;
    const int MAX_CLIP      = 60;
    const int DEFAULT_GIVE  = WEP_APS::MAX_AMMO;
    const int WEIGHT        = 5;
    
    const string SOUND_FIRE = "weapons/m16_3single.wav";
    const string SOUND_COCK = "weapons/357_cock1.wav";
}

class WeaponAps : ScriptBasePlayerWeaponEntity {
    private CBasePlayer@ m_pPlayer = null;
    
    private bool semiAuto1 = false;  // セミオート処理対応。プライマリ
    private bool semiAuto2 = false;  // セミオート処理対応。セカンダリ
    private bool semiAuto3 = false;  // セミオート処理対応。オルト
    private bool semiAutoR = false;  // セミオート処理対応。リロード
    
    private bool ads    = false; // 構え状態
    private bool oldAds = false; // 構え状態変更検出用
    
    private string vModel = "models/kani_gyosen/v_aps.mdl";
    private string pModel = "models/kani_gyosen/p_aps.mdl";
    private string wModel = "models/kani_gyosen/w_aps.mdl";
    
    private float m_flNextAnimTime;
    private int   m_iShell;
    private int   m_iSecondaryAmmo;
    
    /** スポーン */
    void Spawn() {
        Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model(this.wModel) );
        self.m_iDefaultAmmo = WEP_APS::DEFAULT_GIVE;
        self.m_iSecondaryAmmoType = 0;
        self.FallInit();
    }

    /** プリキャッシュ */
    void Precache() {
        g_Game.PrecacheModel( this.vModel );
        g_Game.PrecacheModel( this.pModel );
        g_Game.PrecacheModel( this.wModel );

        m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

        g_Game.PrecacheModel( "models/w_9mmARclip.mdl" );
        g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );

        //These are played by the model, needs changing there
        g_SoundSystem.PrecacheSound( "items/clipinsert1.wav" );
        g_SoundSystem.PrecacheSound( "items/cliprelease1.wav" );
        g_SoundSystem.PrecacheSound( "items/guncock1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/m16_charge.wav" );

        g_SoundSystem.PrecacheSound( WEP_APS::SOUND_FIRE );
        g_SoundSystem.PrecacheSound( WEP_APS::SOUND_COCK );
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1  = WEP_APS::MAX_AMMO;
        info.iMaxAmmo2  = 0;
        info.iMaxClip   = WEP_APS::MAX_CLIP;
        info.iSlot      = 2;
        info.iPosition  = 5;
        info.iFlags     = 0;
        info.iWeight    = WEP_APS::WEIGHT;

        return true;
    }

    /** プレイヤーへ武器追加 */
    bool AddToPlayer( CBasePlayer@ pPlayer ) {
        if( !BaseClass.AddToPlayer( pPlayer ) )
            return false;
            
        @m_pPlayer = pPlayer;
        NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
        m.WriteLong( self.m_iId );
        m.End();

        return true;
    }
    
    // 空撃ちサウンド
    private bool PlayEmptySound() {
        if( self.m_bPlayEmptySound ) {
            self.m_bPlayEmptySound = false;
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, WEP_APS::SOUND_COCK, 0.8, ATTN_NORM, 0, PITCH_NORM );
        }
        
        return false;
    }

    /** デプロイ時 */
    bool Deploy() {
        m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
        
        this.ads    = false;
        this.oldAds = false;
        
        this.semiAuto1 = false;
        this.semiAuto2 = false;
        this.semiAuto3 = false;
        this.semiAutoR = false;
        
        bool ret = self.DefaultDeploy(self.GetV_Model( this.vModel ),
                                      self.GetP_Model( this.pModel ),
                                      WEP_APS::MOTION_DEPLOY, 
                                      WEP_APS::TPV_M_TYPE );
        
        // モーションキャンセルされてしまうため、DefaultDeploy後で
        self.m_flTimeWeaponIdle = g_Engine.time + 3.0; 
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 1.0;
        
        return ret;
    }
    
    /** ホルスター時 */
    void Holster( int skiplocal ) {
        m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
        self.m_fInReload = false;// cancel any reload in progress.
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 
        m_pPlayer.pev.viewmodel = "";
        SetThink( null );
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {

        if( self.m_iClip <= 0 ) {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
            return;
        }

        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, WEP_APS::SOUND_FIRE, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        
        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash  = DIM_GUN_FLASH;

        --self.m_iClip;
        
        
        // アニメーション
        self.SendWeaponAnim(  (this.ads) ? WEP_APS::MOTION_ADS_FIRE : WEP_APS::MOTION_FIRE, 0, 0 );
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        
        Vector vecSrc    = m_pPlayer.GetGunPosition();
        Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
        
        // optimized multiplayer. Widened to make it easier to hit a moving player
        
        if (this.ads) {
            m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_3DEGREES, 8192, BULLET_PLAYER_SAW, 2 );
            m_pPlayer.pev.punchangle.x = Math.RandomLong( -1, 1 );
            
        } else {
            m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_15DEGREES, 8192, BULLET_PLAYER_SAW, 2 );
            m_pPlayer.pev.punchangle.x = Math.RandomLong( -3, 3 );
        }
            

        self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.08;
        if( self.m_flNextPrimaryAttack < g_Engine.time ) {
            self.m_flNextPrimaryAttack = g_Engine.time + 0.08;
        }

        self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
        
        
        float x, y;
        g_Utility.GetCircularGaussianSpread( x, y );
        
        Vector vecDir = vecAiming 
                        + x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right 
                        + y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;

        Vector vecEnd = vecSrc + vecDir * 4096;
        
        TraceResult tr;
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
        
        if ( tr.flFraction < 1.0 ) {
            if ( tr.pHit !is null ) {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if ( pHit is null || pHit.IsBSPModel() ) {
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_SAW );
                }
            }
        }
        
        // 薬莢
        Math.MakeVectors( m_pPlayer.pev.v_angle );
        
        Vector vecShellVelocity = m_pPlayer.pev.velocity 
                             + g_Engine.v_right   * Math.RandomFloat(50, 70) 
                             + g_Engine.v_up      * Math.RandomFloat(100, 150) 
                             + g_Engine.v_forward * 25;
        g_EntityFuncs.EjectBrass(vecSrc
                                    + m_pPlayer.pev.view_ofs
                                    + g_Engine.v_up      * -34
                                    + g_Engine.v_forward * 14
                                    + g_Engine.v_right   * 6,
                                 vecShellVelocity,
                                 m_pPlayer.pev.angles.y,
                                 m_iShell,
                                 TE_BOUNCE_SHELL);
        
    }

    /** セカンダリアタック */
    void SecondaryAttack() {
        // セミオートフラグセット
        if (this.semiAuto2) {
            return;
        }
        this.semiAuto2 = true;
        
        // ADSの切り替え
        self.SendWeaponAnim( (this.ads) ? WEP_APS::MOTION_ADS_OFF : WEP_APS::MOTION_ADS_ON, 0, 0 ); 
        this.ads = !this.ads;
        
        m_pPlayer.pev.fov = m_pPlayer.m_iFOV = (this.ads) ? 45 : 0;
        
        self.m_flNextPrimaryAttack   = g_Engine.time + 0.5;
        self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
        self.m_flTimeWeaponIdle      = g_Engine.time + 5;  // idle pretty soon after shooting.
    }

    /** リロード */
    void Reload() {
        if (self.m_iClip >= WEP_APS::MAX_CLIP) {
            return;
        }
        
        m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
        
        // ADS中なら一旦解除
        if (this.ads) {
            this.ads = false;
            
            self.SendWeaponAnim( WEP_APS::MOTION_ADS_OFF , 0, 0 );
            self.pev.nextthink = g_Engine.time + 0.6;
        } else {
            self.pev.nextthink = g_Engine.time + 0.1;
        }
        SetThink( ThinkFunction( this.DoReload ) );
        
        self.m_flNextPrimaryAttack   = g_Engine.time + 1.0;
        self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
        self.m_flTimeWeaponIdle      = g_Engine.time + 5; 
       
    }
    
    private void DoReload() {
         // クリップが空の場合、ボルト引くモーション
        if (self.m_iClip == 0) {
            self.DefaultReload( WEP_APS::MAX_CLIP, WEP_APS::MOTION_RELOAD_EMPTY, 2.3, 0 );
        } else {
            self.DefaultReload( WEP_APS::MAX_CLIP, WEP_APS::MOTION_RELOAD, 1.7, 0 );
        }
        
        BaseClass.Reload();
    }

    /** アイドル時 */
    void WeaponIdle() {
        self.ResetEmptySound();

        m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

        
        // セミオート処理。ボタンを離したら解除
        if ( !(( m_pPlayer.pev.button & IN_ATTACK )   != 0) ) { semiAuto1 = false; }
        if ( !(( m_pPlayer.pev.button & IN_ATTACK2 )  != 0) ) { semiAuto2 = false; }
        if ( !(( m_pPlayer.pev.button & IN_ALT1 )     != 0) ) { semiAuto3 = false; }
        if ( !(( m_pPlayer.pev.button & IN_RELOAD )   != 0) ) { semiAutoR = false; }
        
        // 一定時間後にアイドルモーション
        if (self.m_flTimeWeaponIdle  > g_Engine.time) {
            return;
        }

        DoIdleMotion();
    }
    
    // アイドルモーション切り替え
    private void DoIdleMotion() {
        if (this.ads) {
            self.SendWeaponAnim( WEP_APS::MOTION_ADS );
            
        } else {
            switch (Math.RandomLong(0, 1)) {
                case 0:  self.SendWeaponAnim( WEP_APS::MOTION_IDLE );     break;
                default: self.SendWeaponAnim( WEP_APS::MOTION_LONGIDLE ); break;
            }
        }
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat(10.0, 15.0);
    }
}

// 武器登録
void RegisterAps() {
    g_CustomEntityFuncs.RegisterCustomEntity( "WeaponAps", WEP_APS::WEP_NAME );
    g_ItemRegistry.RegisterWeapon( WEP_APS::WEP_NAME, "kani_gyosen", "556" );
}
