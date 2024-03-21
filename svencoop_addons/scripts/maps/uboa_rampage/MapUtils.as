/* 
 * 共通管理
 */

class MapUtils {
    
    // 武器リスト
    private array<string> MAP_WEAPONS = {
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
        "weapon_platinumbar",
        "weapon_merikensack",
        "weapon_medkit"
    };
    
    // 定期処理
    void Tick() {
        
        // プレイヤー毎チェック
        for (int i = 1; i <= g_Engine.maxClients; i++) {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
            if ( (pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive()) ) {
                WeaponsCheck(pPlayer);
            }
        }
    }
    
    // 武器をチェック
    private void WeaponsCheck(CBasePlayer@ pPlayer) {
        
        // プレイヤーの所持武器を調べる
        for (uint i = 0; i < MAX_ITEM_TYPES; i++ ) {
            CBasePlayerItem@ pItem = pPlayer.m_rgpPlayerItems(i);
            if (pItem !is null) {                
                // 武器を所持しているならフラグを立てる
                if (IsInItems(MAP_WEAPONS, pItem.GetClassname())) {
                    pItem.pev.iuser4 = 1;
                    
                // 指定以外の武器を持ってるなら除去
                } else {
                    pPlayer.RemovePlayerItem(pItem);
                }
            }
        }
    }
    
    // 配列にあるか
    private bool IsInItems(array<string> items, string target) {
        for (uint i = 0; i < items.length(); i++) {
            if (items[i] == target) {
                return true;
            }
        }
        return false;
    }
}
