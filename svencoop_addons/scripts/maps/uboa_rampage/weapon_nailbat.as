/* 
 * 釘バット
 */
#include "weapon_uboamelee"
class weapon_nailbat : weapon_uboamelee {
    
    void Spawn() {
        Init("nailbat");
    }
    
	bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = UBOAMELEE_MAX_AMMO;
	    info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 8;
        info.iFlags    = 1;
        info.iWeight   = 20;
	    
		return true;
	}
     
    // プライマリアタック
	void PrimaryAttack() {
	    // Rageモードと合わせてスピード、威力調整
	    float dmgBuf = 38.0 + Math.RandomFloat(0.0, 3.0) + (0.5 * mRageLevel);
	    float spdBuf = (mRageLevel > 0) ? 0.2 : 0.5;
	    
        if (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0) {
    	    int randomAnim;
            
            if (mRageLevel == 0) {
                randomAnim = (Math.RandomLong(0, 1) == 1) ? UBOAMELEE_SWING1_1 : UBOAMELEE_SWING2_1;
            } else {
                randomAnim = (Math.RandomLong(0, 1) == 1) ? UBOAMELEE_SWING1_2 : UBOAMELEE_SWING2_2;
            }
            self.SendWeaponAnim(randomAnim, 0, mBody);
            
            
        	m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
            self.m_flCustomDmg = dmgBuf;
    	    
    		SetThink(ThinkFunction(this.AttackDelay1));
    		self.pev.nextthink = g_Engine.time + 0.05;
        
        } else {
            self.SendWeaponAnim(UBOAMELEE_TAUNT2, 0, mBody);
        	m_pPlayer.SetAnimation( PLAYER_DEPLOY );
            g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "This weapon is broken.");
	    }
	    self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
	    self.m_flNextSecondaryAttack = g_Engine.time + spdBuf;
	    
	    WeaponIdle();
	}
    
    // セカンダリアタック
	void SecondaryAttack() {
	    // Rageモードと合わせてスピード、威力調整
	    float dmgBuf = 54.0 + (0.6 * mRageLevel);
	    float spdBuf = (mRageLevel > 0) ? 0.3 : 0.5;
	    	    
        if (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0) {
            if (mRageLevel == 0) {
    	        self.SendWeaponAnim( UBOAMELEE_POWERATTACK_1, 0, mBody );
            } else {
    	        self.SendWeaponAnim( UBOAMELEE_POWERATTACK_2, 0, mBody );
            }
        	m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            self.m_flCustomDmg = dmgBuf;
    	    
    		SetThink(ThinkFunction(this.AttackDelay2));
    		self.pev.nextthink = g_Engine.time + 0.2;
            
        } else {
            self.SendWeaponAnim(UBOAMELEE_TAUNT2, 0, mBody);
        	m_pPlayer.SetAnimation( PLAYER_DEPLOY );
            g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "This weapon is broken.");
	    }
	    self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
	    self.m_flNextSecondaryAttack = g_Engine.time + spdBuf + 0.5;
	    
	    WeaponIdle();
	}
    
    // サードアタック
    void TertiaryAttack() {
        self.SendWeaponAnim( UBOAMELEE_TAUNT1, 0, mBody );
        self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
        
        TurnOnRage(m_pPlayer);
    }
        
	void AttackDelay1() {
	    Swing(0);
	}
    
	void AttackDelay2() {
	    Swing(1);
	}
	
}

string GetNailbatName() {
	return "weapon_nailbat";
}

void RegisterNailbat() {
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_nailbat", GetNailbatName() );
	g_ItemRegistry.RegisterWeapon( GetNailbatName(), "uboa_rampage", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}
