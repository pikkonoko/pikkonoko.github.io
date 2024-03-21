/* 
 * ��
 */

namespace WEP_HARPOON {
    const string WEP_NAME  = "weapon_harpoon";
    const string TPV_M_TYPE  = "squeak";
    
    enum motion_e {
        MOTION_IDLE1 = 0,
        MOTION_STAB1,
        MOTION_STAB2,
        MOTION_SHOOT,
        MOTION_HOLD,
        MOTION_RELOAD,
        MOTION_UNHOOK,
        MOTION_DRAW,
        MOTION_FIDGET
    };
    
    const string SOUND_HITW1 = "weapons/knife_hit_wall1.wav";
    const string SOUND_HITW2 = "weapons/knife_hit_wall2.wav";
    const string SOUND_HITB1 = "weapons/xbow_hitbod1.wav";
    const string SOUND_HITB2 = "weapons/cbar_hitbod3.wav";
    const string SOUND_MISS  = "weapons/knife3.wav";
    const string SOUND_SHOT  = "weapons/xbow_hit2.wav";
    
}

class WeaponHarpoon : ScriptBasePlayerWeaponEntity {
    private CBasePlayer@ m_pPlayer = null;
    private CBaseEntity@ m_pTarget = null;
    
    private bool semiAuto1 = false;  // �Z�~�I�[�g�����Ή��B�v���C�}��
    private bool semiAuto2 = false;  // �Z�~�I�[�g�����Ή��B�Z�J���_��
    private bool semiAuto3 = false;  // �Z�~�I�[�g�����Ή��B�I���g
    private bool semiAutoR = false;  // �Z�~�I�[�g�����Ή��B�����[�h
        
    private string vModel  = "models/kani_gyosen/v_harpoon.mdl";
    private string pModel  = "models/kani_gyosen/p_harpoon.mdl";
    private string pModel2 = "models/kani_gyosen/p_harpoon2.mdl";
    private string wModel  = "models/kani_gyosen/w_harpoon.mdl";
    
    private TraceResult m_trHit;
    private bool shot = false;
    
    private float nextReload;
    private Vector lastAngle;
    
    /** �X�|�[�� */
    void Spawn() {
        self.Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model(this.wModel) );
        self.m_iClip            = -1;
        self.FallInit();    // get ready to fall down.
    }

    /** �v���L���b�V�� */
    void Precache() {
        g_Game.PrecacheModel( this.vModel );
        g_Game.PrecacheModel( this.pModel );
        g_Game.PrecacheModel( this.pModel2 );
        g_Game.PrecacheModel( this.wModel );

        g_SoundSystem.PrecacheSound( WEP_HARPOON::SOUND_HITW1 );
        g_SoundSystem.PrecacheSound( WEP_HARPOON::SOUND_HITW2 );
        g_SoundSystem.PrecacheSound( WEP_HARPOON::SOUND_HITB1 );
        g_SoundSystem.PrecacheSound( WEP_HARPOON::SOUND_HITB2 );
        g_SoundSystem.PrecacheSound( WEP_HARPOON::SOUND_MISS );
        g_SoundSystem.PrecacheSound( WEP_HARPOON::SOUND_SHOT );
        
    }

    /** ������ */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = -1;
        info.iMaxAmmo2 = -1;
        info.iMaxClip  =  0;
        info.iSlot     =  1;
        info.iPosition =  5;
        info.iWeight   =  0;
        return true;
    }
    
    /** �v���C���[�֕���ǉ� */
    bool AddToPlayer( CBasePlayer@ pPlayer ) {
        if( !BaseClass.AddToPlayer( pPlayer ) ) {
            return false;
        }
        
        // �E�����Ƃ��ɃA�C�R�����E�ɕ\��
        @m_pPlayer = pPlayer;
        NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
        m.WriteLong( self.m_iId );
        m.End();

        return true;
    }

    /** �f�v���C�� */
    bool Deploy() {
        @m_pTarget = null;
        this.shot = false;
        this.lastAngle = Vector(0, 0, 0);
        this.nextReload = 0;
        
        this.semiAuto1 = false;
        this.semiAuto2 = false;
        this.semiAuto3 = false;
        this.semiAutoR = false;
        
        bool ret = self.DefaultDeploy(self.GetV_Model( this.vModel ),
                                      self.GetP_Model( this.pModel ),
                                      WEP_HARPOON::MOTION_DRAW, 
                                      WEP_HARPOON::TPV_M_TYPE );
        
        // ���[�V�����L�����Z������Ă��܂����߁ADefaultDeploy���
        self.m_flTimeWeaponIdle = g_Engine.time + 10.0; 
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 1.5;
        
        self.m_flNextSecondaryAttack = g_Engine.time + 2.0; // �X�C�b�`�L�����Z���h�~
        return ret;
    }

    /** �z���X�^�[�� */
    void Holster( int skiplocal ) {
        if ((@m_pTarget !is null) && (m_pTarget.IsAlive())) { 
            m_pTarget.pev.velocity = Vector(0, 0, 30);
            m_pTarget.pev.iuser4 = 0;
        }
        @m_pTarget = null;
        self.m_fInReload = false;// cancel any reload in progress.
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 
        m_pPlayer.pev.viewmodel = "";
        SetThink( null );
    }
    
    /** �v���C�}���A�^�b�N */
    void PrimaryAttack() {
        
        if (this.shot) {
            if ((@m_pTarget !is null) && (m_pTarget.IsAlive())) { 
                // ���h������
                StabRelease();
            } else {
                // �����[�h
                DoReload();
            }
            
        } else {
            StabAttack(false);
        }
    }
    
        
    /** �Z�J���_���A�^�b�N */
    void SecondaryAttack() {
        
        // �Z�~�I�[�g�t���O�Z�b�g
        if (this.semiAuto2) { return; }
        this.semiAuto2 = true;
        
        if (this.shot) {
            if ((@m_pTarget !is null) && (m_pTarget.IsAlive())) { 
                // ���h������
                StabRelease();
            } else {
                // �����[�h
                DoReload();
            }
        // 
        } else {
            StabAttack(true);
        }
    }
    
    /** �����[�h */
    void Reload() {
        // �Z�~�I�[�g�t���O�Z�b�g
        if (this.semiAutoR) { return; }
        this.semiAutoR = true;
        
        if (self.m_fInReload) { return; }
        
        // �����[�h�f�B���C
        if (g_Engine.time <=  this.nextReload + 3.0) { return; }
        this.nextReload = g_Engine.time;
        
        if (this.shot) {
            if ((@m_pTarget !is null) && (m_pTarget.IsAlive())) { 
                // ���h������
                StabRelease();
            } else {
                // �����[�h
                DoReload();
            }
        }
    }
    
    private void DoReload() {        
        self.SendWeaponAnim( WEP_HARPOON::MOTION_RELOAD , 0, 0 );
        m_pPlayer.SetAnimation( PLAYER_DEPLOY ); 
        
        SetThink( ThinkFunction( this.ReloadDelay ) );
        self.pev.nextthink = g_Engine.time + 2.5;
        
        self.m_flNextPrimaryAttack   = g_Engine.time + 3.0;
        self.m_flNextSecondaryAttack = g_Engine.time + 3.0;
        self.m_flTimeWeaponIdle      = g_Engine.time + 10.0;
    }
    
    private void ReloadDelay() {
        this.shot = false;
        m_pPlayer.SetAnimation( PLAYER_DEPLOY ); 
        m_pPlayer.pev.weaponmodel = this.pModel;
    }

    private void StabRelease() {
        TraceResult tr;

        Math.MakeVectors( m_pPlayer.pev.v_angle );
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecEnd = vecSrc + g_Engine.v_forward * 160;

        g_Utility.TraceLine( vecSrc, vecEnd, ignore_monsters, m_pPlayer.edict(), tr );
    
        // �U�����ǂɓ������Ă��Ȃ��Ȃ����
        if ( tr.flFraction >= 1.0 ) {
            if ((@m_pTarget !is null) && (m_pTarget.IsAlive())) { 
                m_pTarget.pev.velocity = Vector(0, 0, 30);
                m_pTarget.pev.iuser4 = 0;
            }
            @m_pTarget = null;
            
            // �������[�V����
            self.SendWeaponAnim( WEP_HARPOON::MOTION_UNHOOK , 0, 0 );
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
        }
    }
    

    private bool StabAttack( bool isCapture) {
        
        bool fDidHit = false;

        TraceResult tr;

        Math.MakeVectors( m_pPlayer.pev.v_angle );
        Vector vecSrc    = m_pPlayer.GetGunPosition();
        Vector vecEnd    = vecSrc + g_Engine.v_forward * 128;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

        // ���菈���O�v�Z
        if ( tr.flFraction >= 1.0 ) {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
            if ( tr.flFraction < 1.0 ) {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if ( pHit is null || pHit.IsBSPModel() ) {
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
                }
                vecEnd = tr.vecEndPos; 
            }
        }
        
        // �A�j���[�V����
        if (isCapture) {
            self.SendWeaponAnim( WEP_HARPOON::MOTION_SHOOT );
            m_pPlayer.pev.weaponmodel = this.pModel2;
            this.shot = true;
        } else {
            self.SendWeaponAnim( (Math.RandomLong( 0, 1 ) == 1) ? WEP_HARPOON::MOTION_STAB1 : WEP_HARPOON::MOTION_STAB2 );
        }
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
        
        
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + ((isCapture) ? 1.5 : 0.5);
        self.m_flTimeWeaponIdle = g_Engine.time + 10.0;
        
        // �~�X
        if ( tr.flFraction >= 1.0 ) {
            // play wiff or swish sound
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, 
                (isCapture) ? WEP_HARPOON::SOUND_SHOT : WEP_HARPOON::SOUND_MISS, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
            
        // �q�b�g
        } else {
            // hit
            fDidHit = true;
            
            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

            float flDamage = (isCapture) ? 10 : 50;
            // �_���[�W�v�Z
            g_WeaponFuncs.ClearMultiDamage();
            pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
            g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );


            float flVol = 1.0;
            bool fHitWorld = true;

            // �^�[�Q�b�g�փq�b�g��
            if ( pEntity !is null )  {
                if ( pEntity.Classify() != CLASS_NONE
                    && pEntity.Classify() != CLASS_MACHINE
                    && pEntity.BloodColor() != DONT_BLEED 
                ) {
                    
                    // �v���C���[�Ȃ牟���o��
                    if ( pEntity.IsPlayer() ) {
                        pEntity.pev.velocity = pEntity.pev.velocity - ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
                    }
                    
                    // �w�b�h�N���u�̏ꍇ�A���h��
                    if ((isCapture) && ( pEntity.GetClassname() == "monster_headcrab" )) {
                        @m_pTarget = pEntity;
                        m_pTarget.pev.iuser4 = g_EngineFuncs.IndexOfEdict(m_pPlayer.edict());
                        
                        this.lastAngle = m_pTarget.pev.angles;
                    }
                    
                    // �X�C���O��
                    switch( Math.RandomLong( 0, 1 ) ) {
                        case 0: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, WEP_HARPOON::SOUND_HITB1, 1, ATTN_NORM ); break;
                        case 1: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, WEP_HARPOON::SOUND_HITB2, 1, ATTN_NORM ); break;
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

            // �ǃq�b�g��
            if( fHitWorld == true ) {
                float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
                fvolbar = 1;

                // also play crowbar strike
                switch( Math.RandomLong( 0, 1 ) ) {
                    case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, WEP_HARPOON::SOUND_HITW1, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
                    case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, WEP_HARPOON::SOUND_HITW2, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
                }
            }

            // delay the decal a bit
            m_trHit = tr;
            SetThink( ThinkFunction( this.AttackDelay ) );
            self.pev.nextthink = g_Engine.time + 0.4;

            m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
        }
        return fDidHit;
    }
    
    // �U����̃f�B���C����
    void AttackDelay() {
        // �f�J�[��
        g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
        
        // ���[�V����
        //self.SendWeaponAnim( (this.shot) ? WEP_HARPOON::MOTION_HOLD : WEP_HARPOON::MOTION_IDLE1);
    }
    
    /** �A�C�h���� */
    void WeaponIdle() {
        self.ResetEmptySound();
        
        // �Z�~�I�[�g�����B�{�^���𗣂��������
        if ( !(( m_pPlayer.pev.button & IN_ATTACK )   != 0) ) { semiAuto1 = false; }
        if ( !(( m_pPlayer.pev.button & IN_ATTACK2 )  != 0) ) { semiAuto2 = false; }
        if ( !(( m_pPlayer.pev.button & IN_ALT1 )     != 0) ) { semiAuto3 = false; }
        if ( !(( m_pPlayer.pev.button & IN_RELOAD )   != 0) ) { semiAutoR = false; }
        
        // ���h�����B�i���Ō�Ɏh�����v���C���[�������̎��j
        if ((@m_pTarget !is null) && (m_pTarget.IsAlive())) { 
            if (m_pTarget.pev.iuser4 == g_EngineFuncs.IndexOfEdict(m_pPlayer.edict())) {
                g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "CAPTURED");
                m_pTarget.SetOrigin( m_pPlayer.pev.origin + g_Engine.v_forward * 75 + g_Engine.v_up * 30);
                m_pTarget.pev.angles = this.lastAngle + Vector(m_pPlayer.pev.angles.x, m_pPlayer.pev.angles.y, -m_pPlayer.pev.angles.z);
            } else {
                @m_pTarget = null;
            }
        }
        
        // ��莞�Ԍ�ɃA�C�h�����[�V����
        if (self.m_flTimeWeaponIdle  > g_Engine.time) {
            return;
        }
        
        DoIdleMotion();
    }
    
    // �A�C�h�����[�V�����؂�ւ�
    private void DoIdleMotion() {
        int anim;
        if (this.shot) {
            self.SendWeaponAnim( WEP_HARPOON::MOTION_HOLD );
            
        } else {
            switch (Math.RandomLong(0, 2)) {
                case 0: self.SendWeaponAnim( WEP_HARPOON::MOTION_IDLE1 );  break;
                case 1: self.SendWeaponAnim( WEP_HARPOON::MOTION_FIDGET ); break;
            }
        }
        self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat(10.0, 15.0);
    }
}


// ����o�^
void RegisterHarpoon() {
    g_CustomEntityFuncs.RegisterCustomEntity( "WeaponHarpoon", WEP_HARPOON::WEP_NAME );
    g_ItemRegistry.RegisterWeapon( WEP_HARPOON::WEP_NAME, "kani_gyosen" );
}
