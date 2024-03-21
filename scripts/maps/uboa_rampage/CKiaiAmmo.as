/* 
 * 気合ゲージクラス
 */
#include "CRageEffect"

const string UBOAKIAI_AMMO_NAME = "ammo_kiai";
const int UBOAKIAI_MAX_AMMO     = 100;
class CKiaiAmmo : ScriptBasePlayerAmmoEntity {
	void Spawn() {
		Precache();
		g_EntityFuncs.SetModel( self, "models/uboa_rampage/sincube.mdl" );
		BaseClass.Spawn();
	    
	    self.pev.rendermode  = kRenderNormal;
        self.pev.renderfx    = kRenderFxGlowShell;
        self.pev.renderamt   = 4;
        self.pev.rendercolor = Vector(128, 128, 128);
	}
	
	void Precache() {
		g_Game.PrecacheModel( "models/uboa_rampage/sincube.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}

	bool AddAmmo( CBaseEntity@ pither ) {
		if( pither.GiveAmmo( UBOAKIAI_MAX_AMMO, UBOAKIAI_AMMO_NAME, UBOAKIAI_MAX_AMMO ) != -1 ) { 
		    int playerIndex = g_EngineFuncs.IndexOfEdict(pither.edict());
		    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(playerIndex);
		    
		    // RAGE発動可能メッセージ
		    CRageEffect rgeff;
		    rgeff.ReadyEffect(pPlayer);
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

void RegisterKiaiAmmo() {
	g_CustomEntityFuncs.RegisterCustomEntity( "CKiaiAmmo", UBOAKIAI_AMMO_NAME);
}