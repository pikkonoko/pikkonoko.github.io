/**
 * マップの仕掛け。呼び出し用
 */

namespace MAP_GIMMICK {
    int kagokaniCnt = 0;
    const string SPRITE_GET = "sprites/kani_gyosen/get.spr";
    const string SOUND_GET  = "buttons/blip1.wav";
    
    // プリキャッシュ
    void Precache() {
        g_Game.PrecacheGeneric("sound/" + SOUND_GET);
        g_SoundSystem.PrecacheSound(SOUND_GET);
        
        g_Game.PrecacheGeneric(SPRITE_GET);
        g_Game.PrecacheModel(SPRITE_GET);
    }
}

/** ゴムボート(fushable)数制限（マップトリガー用） */
void EntCallGomBoat(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue) {
    int cnt = 0;
    
    CBaseEntity@ pEnt = null;
    while ((@pEnt = g_EntityFuncs.FindEntityByClassname(pEnt, "func_pushable")) !is null) {
        cnt++;
    }
    
    //g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "count:" + cnt);
    
    // 制限数を超えてなければ作成Entコール
    if (cnt <= 10) {
        g_EntityFuncs.FireTargets("cent_gomubo", null, null, USE_ON);
    }
}

/** 籠エリア（マップトリガー用） */
void EntCallKago(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue) {
    
    // trigger_multiple で呼び出すことで、下記となるらしい
    //  pActivator = trigger_multipleエリアに入ったオブジェクト。箱やプレイヤーなど
    //  pCaller    = trigger_multipleエリアのエンティティ
    
    //g_PlayerFuncs.ClientPrintAll(HUD_PRINTCENTER, "activator: " + pActivator.pev.targetname + "\ncaller: "  + pCaller.pev.targetname);
    
    const int OFFSET = 20;
    const int SPEED  = 25;
    
    // ヘッドクラブの場合
    if ((@pActivator !is null)
        && (pActivator.GetClassname() == "monster_headcrab" ) 
        && (pActivator.pev.iuser4 == 0)
    ) {
        
        // 画像表示        
        NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
        m.WriteByte(TE_PROJECTILE);
        m.WriteCoord(pActivator.pev.origin.x);
        m.WriteCoord(pActivator.pev.origin.y);
        m.WriteCoord(pActivator.pev.origin.z + OFFSET);
        m.WriteCoord(0);
        m.WriteCoord(0);
        m.WriteCoord(SPEED);
        m.WriteShort(g_EngineFuncs.ModelIndex(MAP_GIMMICK::SPRITE_GET));
        m.WriteByte(2); // 有効時間 x秒
        m.WriteByte(0); // 所持者ID
        m.End();
        
        // 再生
        g_SoundSystem.PlaySound(pActivator.edict(), CHAN_AUTO, MAP_GIMMICK::SOUND_GET, 1.0f, ATTN_NONE, 0, 100);
        
        // イベント用エンティティをコール
        g_EntityFuncs.FireTargets("mm_kago", null, null, USE_ON);
        // オブジェクトを削除
        g_EntityFuncs.Remove(pActivator);
    }
}

/** 蟹カウンター（マップトリガー用） */
void EntCallKagoKaniCnt(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue) {
    
    // 5x5のサイズ
    MAP_GIMMICK::kagokaniCnt %= 25;
    MAP_GIMMICK::kagokaniCnt++;
    
    //g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "cnt" + MAP_GIMMICK::kagokaniCnt);
    
    CBaseEntity@ pTarget = null;
    while ((@pTarget = g_EntityFuncs.FindEntityByTargetname( pTarget, "cent_kagokani" + MAP_GIMMICK::kagokaniCnt )) !is null) {
        pTarget.Use(null, null, USE_ON);
    }
}

/** 罠（マップトリガー用） */
void EntCallWana(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue) {
    // 蓋を開ける
    string entName = pCaller.pev.targetname;
    entName.Replace("mm_", "plt_");
    g_EntityFuncs.FireTargets(entName, null, null, USE_ON);
    
}

/** 蟹スポーン（マップトリガー用） */
void EntCallKaniOn3(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue) {
    
    // 一旦全部OFF
    CBaseEntity@ pTarget = null;
    for (uint i = 1; i <= 9; i++) {
        while ((@pTarget = g_EntityFuncs.FindEntityByTargetname( pTarget, "sq_kani" + i )) !is null) {
            pTarget.Use(null, null, USE_OFF);
        }
    }
    
    array<uint> numList = {1, 2, 3, 4, 5, 6, 7, 8, 9};
    array<uint> retList = {};
    int num;
    
    // 元の配列から３つ選ぶ
    for (uint i = 0; i < 3; i++) {
        num = Math.RandomLong(0, numList.length() -1);
        retList.insertLast(numList[num]);
        numList.removeAt(num);
    }
    
    //string buf = "";
    //番号のエンティティを実行
    for (uint i = 0; (i < retList.length()) && (retList.length() > 0); i++) {
        //buf = buf + retList[i] + " ";
        
        @pTarget = null;
        while ((@pTarget = g_EntityFuncs.FindEntityByTargetname( pTarget, "sq_kani" + retList[i] )) !is null) {
            pTarget.Use(null, null, USE_ON);
        }
    }
    
    //g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "rand=" + buf);
}

/** 蟹スポーン全部（マップトリガー用） */
void EntCallKaniOnAll(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue) {
    CBaseEntity@ pTarget = null;
    for (int i = 1; i <= 9; i++) {
        while ((@pTarget = g_EntityFuncs.FindEntityByTargetname( pTarget, "sq_kani" + i )) !is null) {
            pTarget.Use(null, null, USE_ON);
        }
    }
}
