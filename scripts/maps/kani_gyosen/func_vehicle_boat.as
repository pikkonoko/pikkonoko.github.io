/*
 * func_vehicle_boat
 *
 * ※func_vehicle_custom の改造版
 */

/** Boat用 定数 */
namespace Boat {
    const string ENT_NAME  = "func_vehicle_boat";
    const string CTRL_NAME = "func_vehicle_controls";
    
    
    // 加速補正値
    const double SPEED0_ACC  = 0.005000000000000000;
    const double SPEED1_ACC  = 0.002142857142857143;
    const double SPEED2_ACC  = 0.003333333333333334;
    const double SPEED3_ACC  = 0.004166666666666667;
    const double SPEED4_ACC  = 0.004000000000000000;
    const double SPEED5_ACC  = 0.003800000000000000;
    const double SPEED6_ACC  = 0.004500000000000000;
    const double SPEED7_ACC  = 0.004250000000000000;
    const double SPEED8_ACC  = 0.002666666666666667;
    const double SPEED9_ACC  = 0.002285714285714286;
    const double SPEED10_ACC = 0.001875000000000000;
    const double SPEED11_ACC = 0.001444444444444444;
    const double SPEED12_ACC = 0.001200000000000000;
    const double SPEED13_ACC = 0.000916666666666666;
    const double SPEED14_ACC = 0.001444444444444444;

    const int START_SND_PITCH = 60;
    const int MAX_SND_PITCH   = 200;
    const int MAX_SND_SPEED   = 1500;
    
        
    const string SOUND_ENGINE  = "plats/vehicle1.wav";
    const string SOUND_BRAKE   = "misc/truck_stop.wav";
    const string SOUND_STARTON = "plats/talkstop1.wav";
    
    const float BSP_DEFDIR = 180.0;   // Hammerブラシ左向き基準
    
}

enum FuncVehicleFlags {
    SF_VEHICLE_NODEFAULTCONTROLS = 1 << 0 //Don't make a controls volume by default
}

/**
 * 乗り物（Vehicle） クラス
 */
class VehicleBoat : ScriptBaseEntity {
    
    private CPathTrack@  m_ppath;
    private float        m_length;
    private float        m_width;
    private float        m_height;
    private float        m_speed;
    private float        m_dir;
    private float        m_startSpeed;
    private Vector       m_controlMins;
    private Vector       m_controlMaxs;
    private int          m_soundPlaying;
    private int          m_acceleration;
    private float        m_flVolume;
    private float        m_flBank;
    private float        m_oldSpeed;
    private int          m_iTurnAngle;
    private float        m_flSteeringWheelDecay;
    private float        m_flAcceleratorDecay;
    private float        m_flTurnStartTime;
    private float        m_flLaunchTime;
    private float        m_flLastNormalZ;
    private float        m_flCanTurnNow;
    private float        m_flUpdateSound;
    private Vector       m_vFrontLeft;
    private Vector       m_vFront;
    private Vector       m_vFrontRight;
    private Vector       m_vBackLeft;
    private Vector       m_vBack;
    private Vector       m_vBackRight;
    private Vector       m_vSurfaceNormal;
    private Vector       m_vVehicleDirection;
    private CBasePlayer@ m_pDriver;

    private bool mIsMoved = false;
        
    private int m_plIdx = 0;
    
    // キー設定
    bool KeyValue( const string& in szKey, const string& in szValue ) {
        if (szKey == "length") {
            m_length = atof(szValue);
            return true;
        } else if (szKey == "width") {
            m_width = atof(szValue);
            return true;
        } else if (szKey == "height") {
            m_height = atof(szValue);
            return true;
        } else if (szKey == "startspeed") {
            m_startSpeed = atof(szValue);
            return true;
        } else if (szKey == "volume") {
            m_flVolume = float(atoi(szValue));
            m_flVolume *= 0.1;
            return true;
        } else if (szKey == "bank") {
            m_flBank = atof(szValue);
            return true;
        } else if (szKey == "acceleration") {
            m_acceleration = atoi(szValue);
            
            if (m_acceleration < 1) {
                m_acceleration = 1;
            } else if (m_acceleration > 10) {
                m_acceleration = 10;
            }
            return true;
        } else {
            return BaseClass.KeyValue( szKey, szValue );
        }
    }
    
    // 次動作フレームの設定？
    void NextThink(float thinkTime, const bool alwaysThink) {
        if (alwaysThink) {
            self.pev.flags |= FL_ALWAYSTHINK;
        } else {
            self.pev.flags &= ~FL_ALWAYSTHINK;
        }
        self.pev.nextthink = thinkTime;
    }
    
    // 衝突してブロックされたとき
    void Blocked(CBaseEntity@ pOther) {
        entvars_t@ pevOther = pOther.pev;
        
        // debug
        //g_PlayerFuncs.ClientPrintAll(HUD_PRINTCENTER, "x=" + self.pev.velocity.x + " y=" + self.pev.velocity.y + " z=" + self.pev.velocity.z);

        if (pevOther.FlagBitSet(FL_ONGROUND) && pevOther.groundentity !is null && pevOther.groundentity.vars is self.pev) {
            pevOther.velocity = self.pev.velocity;
            return;
        } else {
            pevOther.velocity = (pevOther.origin - self.GetOrigin()).Normalize() * 300;
            pevOther.velocity.z += 300;
        }
        
        // 味方でない場合は、轢殺ダメージ
        int cl = pOther.Classify();
        //if (( cl != CLASS_PLAYER) && ( cl != CLASS_PLAYER_ALLY) && ( cl != CLASS_HUMAN_PASSIVE)) {
        if (cl != CLASS_PLAYER)  {
            Math.MakeVectors(self.pev.angles);

            Vector vFrontLeft  = (g_Engine.v_forward * -1) * (m_length * 0.5);
            Vector vFrontRight = (g_Engine.v_right * -1)   * (m_width * 0.5);
            Vector vBackLeft   = self.GetOrigin() + vFrontLeft - vFrontRight;
            Vector vBackRight  = self.GetOrigin() - vFrontLeft + vFrontRight;
            float minx = Math.min(vBackLeft.x, vBackRight.x);
            float maxx = Math.max(vBackLeft.x, vBackRight.x);
            float miny = Math.min(vBackLeft.y, vBackRight.y);
            float maxy = Math.max(vBackLeft.y, vBackRight.y);
            float minz = self.pev.origin.z;
            float maxz = self.pev.origin.z + (2 * abs(int(self.pev.mins.z - self.pev.maxs.z)));

            if (   pOther.pev.origin.x < minx || pOther.pev.origin.x > maxx
                || pOther.pev.origin.y < miny || pOther.pev.origin.y > maxy
                || pOther.pev.origin.z < minz || pOther.pev.origin.z > maxz) {
                pOther.TakeDamage(self.pev, self.pev, 150, DMG_CRUSH);
            }
        }
    }
    
    void OnDestroy() {
        StopSound();
        SetThink(null);
    }

    // 初期化SPAWN時
    void Spawn() {

        self.pev.speed = 0;
        self.pev.velocity = g_vecZero;
        self.pev.avelocity = g_vecZero;
        
        self.pev.max_health = 3000;
        self.pev.health     = 3000;
        m_speed  = 160;
        m_acceleration = 15;
        
        self.pev.impulse = int(m_speed);
        self.pev.takedamage = DAMAGE_NO;
        
        m_width  = 96;
        m_length = 240;
        m_height = 48;
        m_dir = 1;
        m_flTurnStartTime = -1;

        self.pev.solid = SOLID_BSP;
        self.pev.movetype = MOVETYPE_PUSH;
        
        //self.pev.mins = Vector(-60, -60, -100);
        //self.pev.maxs = Vector( 60,  60,  100);
        

        g_EntityFuncs.SetModel(self, self.pev.model);
        g_EntityFuncs.SetSize(self.pev, self.pev.mins, self.pev.maxs);
        g_EntityFuncs.SetOrigin(self, self.GetOrigin());

        self.pev.oldorigin = self.GetOrigin();
        
        if( !self.pev.SpawnFlagBitSet( SF_VEHICLE_NODEFAULTCONTROLS ) ) {
            m_controlMins = self.pev.mins;
            m_controlMaxs = self.pev.maxs;
            m_controlMaxs.z += 72;
        }
        
        NextThink(self.pev.ltime + 0.1, false);
        SetThink(ThinkFunction(this.Find));
        Precache();
        
    }
    
    // プリキャッシュ
    void Precache() {
        if (m_flVolume == 0) {
            m_flVolume = 1;
        }
        
        // 動作音
        g_SoundSystem.PrecacheSound(Boat::SOUND_ENGINE);
        g_SoundSystem.PrecacheSound(Boat::SOUND_BRAKE);
        g_SoundSystem.PrecacheSound(Boat::SOUND_STARTON);
        
        self.pev.noise = Boat::SOUND_ENGINE;  
        
    }
    
    // ファクション
    int Classify()  {
        return CLASS_PLAYER_ALLY;
    }
    

    // 使用（動作）
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value) {
        float delta = value;

        if (useType != USE_SET) {
            if( !self.ShouldToggle( useType, self.pev.speed != 0 ))
                return;

            if (self.pev.speed == 0) {
                self.pev.speed = m_speed * m_dir;
                Next();
            } else {
                self.pev.speed = 0;
                self.pev.velocity = g_vecZero;
                self.pev.avelocity = g_vecZero;
                StopSound();
                SetThink(null);
            }
        }

        if (delta < 10) {
            if (delta < 0 && self.pev.speed > 145) {
                StopSound();
            }

            float flSpeedRatio = delta;

            // 前進 value = 1
            if (delta > 0) {
                flSpeedRatio = self.pev.speed / m_speed;

                if (self.pev.speed < 0)
                    flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + Boat::SPEED0_ACC;
                else if (self.pev.speed < 10)
                    flSpeedRatio = m_acceleration * 0.0006 + flSpeedRatio + Boat::SPEED1_ACC;
                else if (self.pev.speed < 20)
                    flSpeedRatio = m_acceleration * 0.0007 + flSpeedRatio + Boat::SPEED2_ACC;
                else if (self.pev.speed < 30)
                    flSpeedRatio = m_acceleration * 0.0007 + flSpeedRatio + Boat::SPEED3_ACC;
                else if (self.pev.speed < 45)
                    flSpeedRatio = m_acceleration * 0.0007 + flSpeedRatio + Boat::SPEED4_ACC;
                else if (self.pev.speed < 60)
                    flSpeedRatio = m_acceleration * 0.0008 + flSpeedRatio + Boat::SPEED5_ACC;
                else if (self.pev.speed < 80)
                    flSpeedRatio = m_acceleration * 0.0008 + flSpeedRatio + Boat::SPEED6_ACC;
                else if (self.pev.speed < 100)
                    flSpeedRatio = m_acceleration * 0.0009 + flSpeedRatio + Boat::SPEED7_ACC;
                else if (self.pev.speed < 150)
                    flSpeedRatio = m_acceleration * 0.0008 + flSpeedRatio + Boat::SPEED8_ACC;
                else if (self.pev.speed < 225)
                    flSpeedRatio = m_acceleration * 0.0007 + flSpeedRatio + Boat::SPEED9_ACC;
                else if (self.pev.speed < 300)
                    flSpeedRatio = m_acceleration * 0.0006 + flSpeedRatio + Boat::SPEED10_ACC;
                else if (self.pev.speed < 400)
                    flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + Boat::SPEED11_ACC;
                else if (self.pev.speed < 550)
                    flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + Boat::SPEED12_ACC;
                else if (self.pev.speed < 800)
                    flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + Boat::SPEED13_ACC;
                else
                    flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + Boat::SPEED14_ACC;
                
            // 後退 value = -1
            } else if (delta < 0) {
                flSpeedRatio = self.pev.speed / m_speed;
                
                if (flSpeedRatio > 0)
                    flSpeedRatio -= 0.02;
                else if (flSpeedRatio <= 0 && flSpeedRatio > -0.1)
                    flSpeedRatio -= 0.0075;
                else if (flSpeedRatio <= 0.1 && flSpeedRatio > -0.2)
                    flSpeedRatio -= 0.015;
                else if (flSpeedRatio <= 0.2 && flSpeedRatio > -0.4)
                    flSpeedRatio -= 0.02;
                else if (flSpeedRatio <= 0.4 && flSpeedRatio > -0.6)
                    flSpeedRatio -= 0.015;
                else if (flSpeedRatio <= 0.6 && flSpeedRatio > -0.8)
                    flSpeedRatio -= - 0.03;
                else if (flSpeedRatio <= 0.8)
                    flSpeedRatio -= 0.04;

            }

            if (flSpeedRatio > 1) {
                flSpeedRatio = 1;
            } else if (flSpeedRatio < -0.85) {
                flSpeedRatio = -0.85;
            }

            self.pev.speed = m_speed * flSpeedRatio;
            Next();
            m_flAcceleratorDecay = g_Engine.time + 0.25;
            
        // 回転
        } else {
            if (g_Engine.time > m_flCanTurnNow) {
                // 左へ回転 value = 20
                if (delta == 20) {
                    m_iTurnAngle++;
                    m_flSteeringWheelDecay = g_Engine.time + 0.075;

                    if (m_iTurnAngle > 8) {
                        m_iTurnAngle = 8;
                    }
                    
                // 右へ回転 value = 30
                } else if (delta == 30) {
                    m_iTurnAngle--;
                    m_flSteeringWheelDecay = g_Engine.time + 0.075;

                    if (m_iTurnAngle < -8) {
                        m_iTurnAngle = -8;
                    }
                }

                m_flCanTurnNow = g_Engine.time + 0.05;
            }
        }
    }
    
    int ObjectCaps() { 
        return (BaseClass.ObjectCaps() & ~FCAP_ACROSS_TRANSITION) | FCAP_DIRECTIONAL_USE; 
    }
    
    void OverrideReset() {
        NextThink(self.pev.ltime + 0.1, false);
        SetThink(ThinkFunction(this.NearestPath));
    }
    
    // 回転チェック
    void CheckTurning() {
        TraceResult tr;
        Vector vecStart, vecEnd;

        if (m_iTurnAngle < 0) {
            if (self.pev.speed > 0) {
                vecStart = m_vFrontLeft;
                vecEnd = vecStart - g_Engine.v_right * 16;
            } else if (self.pev.speed < 0) {
                vecStart = m_vBackLeft;
                vecEnd = vecStart + g_Engine.v_right * 16;
            }

            g_Utility.TraceLine(vecStart, vecEnd, ignore_monsters, dont_ignore_glass, self.edict(), tr);

            if (tr.flFraction != 1) {
                m_iTurnAngle = 1;
            }
            
        } else if (m_iTurnAngle > 0) {
            if (self.pev.speed > 0) {
                vecStart = m_vFrontRight;
                vecEnd = vecStart + g_Engine.v_right * 16;
            } else if (self.pev.speed < 0) {
                vecStart = m_vBackRight;
                vecEnd = vecStart - g_Engine.v_right * 16;
            }

            g_Utility.TraceLine(vecStart, vecEnd, ignore_monsters, dont_ignore_glass, self.edict(), tr);

            if (tr.flFraction != 1) {
                m_iTurnAngle = -1;
            }
        }

        if (self.pev.speed <= 0) {
            return;
        }

        float speed;
        int turning = int(abs(m_iTurnAngle));

        if (turning > 4) {
            if (m_flTurnStartTime != -1) {
                float time = g_Engine.time - m_flTurnStartTime;

                if (time >= 0)
                    speed = m_speed * 0.98;
                else if (time > 0.3)
                    speed = m_speed * 0.95;
                else if (time > 0.6)
                    speed = m_speed * 0.9;
                else if (time > 0.8)
                    speed = m_speed * 0.8;
                else if (time > 1)
                    speed = m_speed * 0.7;
                else if (time > 1.2)
                    speed = m_speed * 0.5;
                else
                    speed = time;
            } else  {
                m_flTurnStartTime = g_Engine.time;
                speed = m_speed;
            }
            
        } else {
            m_flTurnStartTime = -1;
            speed = (turning > 2) ? m_speed * 0.9 : m_speed;
        }

        if (speed < self.pev.speed) {
            self.pev.speed -= m_speed * 0.1;
        }
    }
    
    // 衝突検出
    void CollisionDetection() {
        TraceResult tr;
        Vector vecStart, vecEnd;
        float flDot;

        if (self.pev.speed < 0) {
            vecStart = m_vBackLeft;
            vecEnd = vecStart + (g_Engine.v_forward * 16);
            g_Utility.TraceLine(vecStart, vecEnd, ignore_monsters, dont_ignore_glass, self.edict(), tr);

            if (tr.flFraction != 1) {
                flDot = DotProduct(g_Engine.v_forward, tr.vecPlaneNormal * -1);

                if (flDot < 0.7 && tr.vecPlaneNormal.z < 0.1) {
                    m_vSurfaceNormal = tr.vecPlaneNormal;
                    m_vSurfaceNormal.z = 0;
                    self.pev.speed *= 0.99;
                } else if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0) {
                    self.pev.speed *= -1;
                } else {
                    m_vSurfaceNormal = tr.vecPlaneNormal;
                }

            }

            vecStart = m_vBackRight;
            vecEnd = vecStart + (g_Engine.v_forward * 16);
            g_Utility.TraceLine(vecStart, vecEnd, ignore_monsters, dont_ignore_glass, self.edict(), tr);

            if (tr.flFraction == 1) {
                vecStart = m_vBack;
                vecEnd = vecStart + (g_Engine.v_forward * 16);
                g_Utility.TraceLine(vecStart, vecEnd, ignore_monsters, dont_ignore_glass, self.edict(), tr);

                if (tr.flFraction == 1) {
                    return;
                }
            }

            flDot = DotProduct(g_Engine.v_forward, tr.vecPlaneNormal * -1);

            if (flDot >= 0.7) {
                if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0) {
                    self.pev.speed *= -1;
                } else {
                    m_vSurfaceNormal = tr.vecPlaneNormal;
                }
                
            } else if (tr.vecPlaneNormal.z < 0.1) {
                m_vSurfaceNormal = tr.vecPlaneNormal;
                m_vSurfaceNormal.z = 0;
                self.pev.speed *= 0.99;
            } else if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0) {
                self.pev.speed *= -1;
            } else {
                m_vSurfaceNormal = tr.vecPlaneNormal;
            }
            
        } else if (self.pev.speed > 0) {
            vecStart = m_vFrontRight;
            vecEnd = vecStart - (g_Engine.v_forward * 16);
            g_Utility.TraceLine(vecStart, vecEnd, dont_ignore_monsters, dont_ignore_glass, self.edict(), tr);

            if (tr.flFraction == 1) {
                vecStart = m_vFrontLeft;
                vecEnd = vecStart - (g_Engine.v_forward * 16);
                g_Utility.TraceLine(vecStart, vecEnd, ignore_monsters, dont_ignore_glass, self.edict(), tr);

                if (tr.flFraction == 1) {
                    vecStart = m_vFront;
                    vecEnd = vecStart - (g_Engine.v_forward * 16);
                    g_Utility.TraceLine(vecStart, vecEnd, ignore_monsters, dont_ignore_glass, self.edict(), tr);

                    if (tr.flFraction == 1) {
                        return;
                    }
                }
            }

            flDot = DotProduct(g_Engine.v_forward, tr.vecPlaneNormal * -1);

            if (flDot <= -0.7) {
                if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0) {
                    self.pev.speed *= -1;
                } else {
                    m_vSurfaceNormal = tr.vecPlaneNormal;
                }
            } else if (tr.vecPlaneNormal.z < 0.1) {
                m_vSurfaceNormal = tr.vecPlaneNormal;
                m_vSurfaceNormal.z = 0;
                self.pev.speed *= 0.99;
            } else if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0) {
                self.pev.speed *= -1;
            } else {
                m_vSurfaceNormal = tr.vecPlaneNormal;
            }
        }
    }
        
    // 地面凹凸補正
    void TerrainFollowing() {
        /*
        TraceResult tr;
        g_Utility.TraceLine(self.pev.origin, self.pev.origin + Vector(0, 0, (m_height + 48) * -1), ignore_monsters, dont_ignore_glass, self.edict(), tr);

        if (tr.flFraction != 1) {
            m_vSurfaceNormal = tr.vecPlaneNormal; // 面法線に従う
        } else if (( tr.fInWater != 0 ) || (tr.vecEndPos.z < -2048)) {
            m_vSurfaceNormal = Vector(0, 0, 1);   //  平行方向
        }
        */
        m_vSurfaceNormal = Vector(0, 0, 1);   //  平行方向
    }
   
    // 次フレーム用補正動作？
    void Next() {
        Vector vGravityVector = g_vecZero;
        Math.MakeVectors(self.pev.angles);

        Vector forward = (g_Engine.v_forward * -1) * (m_length * 0.5);
        Vector right   = (g_Engine.v_right   * -1) * (m_width  * 0.5);
        Vector up      = g_Engine.v_up * 16;

        m_vFrontRight    = self.GetOrigin() + forward - right + up;
        m_vFrontLeft     = self.GetOrigin() + forward + right + up;
        m_vFront         = self.GetOrigin() + forward + up;
        m_vBackLeft      = self.GetOrigin() - forward - right + up;
        m_vBackRight     = self.GetOrigin() - forward + right + up;
        m_vBack          = self.GetOrigin() - forward + up;
        m_vSurfaceNormal = g_vecZero;
        
        CheckTurning();

        if (g_Engine.time > m_flSteeringWheelDecay) {
            m_flSteeringWheelDecay = g_Engine.time + 0.1;

            if (m_iTurnAngle < 0) {
                m_iTurnAngle++;
            } else if (m_iTurnAngle > 0) {
                m_iTurnAngle--;
            }
        }

        if (g_Engine.time > m_flAcceleratorDecay and m_flLaunchTime == -1) {
            if (self.pev.speed < 0) {
                self.pev.speed += 20;

                if (self.pev.speed > 0) {
                    self.pev.speed = 0;
                }
            } else if (self.pev.speed > 0) {
                self.pev.speed -= 20;

                if (self.pev.speed < 0) {
                    self.pev.speed = 0;
                }
            }
        }
        
        //Moved here to make sure sounds are always handled correctly
        if (g_Engine.time > m_flUpdateSound) {
            UpdateSound();
            m_flUpdateSound = g_Engine.time + 1;
        }

        if (self.pev.speed == 0) {
            m_iTurnAngle = 0;
            self.pev.avelocity = g_vecZero;
            self.pev.velocity = g_vecZero;
            SetThink(ThinkFunction(this.Next));
            NextThink(self.pev.ltime + 0.1, true);
            return;
        }

        TerrainFollowing();
        CollisionDetection();

        if (m_vSurfaceNormal == g_vecZero) {
            if (m_flLaunchTime != -1) {
                vGravityVector = Vector(0, 0, 0);
                vGravityVector.z = (g_Engine.time - m_flLaunchTime) * -35;

                if (vGravityVector.z < -400) {
                    vGravityVector.z = -400;
                }
            } else {
                m_flLaunchTime = g_Engine.time;
                vGravityVector = Vector(0, 0, 0);
                self.pev.velocity = self.pev.velocity * 1.5;
            }

            m_vVehicleDirection = g_Engine.v_forward * -1;
            
        } else {
            m_vVehicleDirection = CrossProduct(m_vSurfaceNormal, g_Engine.v_forward);
            m_vVehicleDirection = CrossProduct(m_vSurfaceNormal, m_vVehicleDirection);

            Vector angles = Math.VecToAngles(m_vVehicleDirection);
            angles.y += 180;

            if (m_iTurnAngle != 0) {
                angles.y += m_iTurnAngle;
            }

            angles = FixupAngles(angles);
            self.pev.angles = FixupAngles(self.pev.angles);

            float vx = Math.AngleDistance(angles.x, self.pev.angles.x);
            float vy = Math.AngleDistance(angles.y, self.pev.angles.y);

            if (vx > 10) {
                vx = 10;
            } else if (vx < -10) {
                vx = -10;
            }

            if (vy > 10) {
                vy = 10;
            } else if (vy < -10) {
                vy = -10;
            }

            self.pev.avelocity.y = int(vy * 10);
            self.pev.avelocity.x = int(vx * 10);
            m_flLaunchTime = -1;
            m_flLastNormalZ = m_vSurfaceNormal.z;
        }

        Math.VecToAngles(m_vVehicleDirection);

        /*
        if (g_Engine.time > m_flUpdateSound)
        {
            UpdateSound();
            m_flUpdateSound = g_Engine.time + 1;
        }
        */

        if (m_vSurfaceNormal == g_vecZero) {
            self.pev.velocity = self.pev.velocity + vGravityVector;
        } else {
            self.pev.velocity = m_vVehicleDirection.Normalize() * self.pev.speed;
        }

        SetThink(ThinkFunction(this.Next));
        NextThink(self.pev.ltime + 0.1, true);
    }
    
    // 角度補正
    private float Fix(float angle) {
        while (angle < 0) {
            angle += 360;
        }
        while (angle > 360) {
            angle -= 360;
        }
        return angle;
    }
    
    // 角度補正 xyz
    private Vector FixupAngles(Vector v) {
        v.x = Fix(v.x);
        v.y = Fix(v.y);
        v.z = Fix(v.z);
        
        return v;
    }

    // エンティティ検索
    void Find() {
        @m_ppath = cast<CPathTrack@>( g_EntityFuncs.FindEntityByTargetname( null, self.pev.target ) );
        if (m_ppath is null) {
            return;
        }

        entvars_t@ pevTarget = m_ppath.pev;
        if (!pevTarget.ClassNameIs( "path_track" )) {
            //g_Game.AlertMessage(at_error, "func_vehicle_boat must be on a path of path_track\n");
            @m_ppath = null;
            return;
        }
        

        Vector nextPos = pevTarget.origin;
        nextPos.z += m_height;

        Vector look = nextPos;
        look.z -= m_height;
        m_ppath.LookAhead(look, look, m_length, true);
        look.z += m_height;

        self.pev.angles = Math.VecToAngles(look - nextPos);
        self.pev.angles.y += 180;

        g_EntityFuncs.SetOrigin(self, nextPos);
        NextThink(self.pev.ltime + 0.1, false);
        SetThink(ThinkFunction(this.Next));
        self.pev.speed = m_startSpeed;
        UpdateSound();
    }

    // 最寄りPATH？検索
    void NearestPath() {
        CBaseEntity@ pTrack = null;
        CBaseEntity@ pNearest = null;
        float dist = 0.0f;
        float closest = 1024;

        while ((@pTrack = @g_EntityFuncs.FindEntityInSphere(pTrack, self.GetOrigin(), 1024)) !is null) {
            if ((pTrack.pev.flags & (FL_CLIENT | FL_MONSTER)) == 0 && pTrack.pev.ClassNameIs( "path_track" )) {
                dist = (self.GetOrigin() - pTrack.GetOrigin()).Length();

                if (dist < closest) {
                    closest = dist;
                    @pNearest = @pTrack;
                }
            }
        }

        if (pNearest is null) {
            g_Game.AlertMessage(at_console, "Can't find a nearby track !!!\n");
            SetThink(null);
            return;
        }

        g_Game.AlertMessage(at_aiconsole, "TRAIN: %1, Nearest track is %2\n", self.pev.targetname, pNearest.pev.targetname);
        @pTrack = cast<CPathTrack@>(pNearest).GetNext();

        if (pTrack !is null) {
            if ((self.GetOrigin() - pTrack.GetOrigin()).Length() < (self.GetOrigin() - pNearest.GetOrigin()).Length()) {
                @pNearest = pTrack;
            }
        }

        @m_ppath = cast<CPathTrack@>(pNearest);

        if (self.pev.speed != 0) {
            NextThink(self.pev.ltime + 0.1, false);
            SetThink(ThinkFunction(this.Next));
        }
    }

    void SetTrack(CPathTrack@ track) {
        @m_ppath = @track.Nearest(self.GetOrigin()); 
    }
    
    void SetControls(entvars_t@ pevControls) {
        Vector offset = pevControls.origin - self.pev.oldorigin;
        m_controlMins = pevControls.mins + offset;
        m_controlMaxs = pevControls.maxs + offset;
    }

    bool OnControls(entvars_t@ pevTest) {
        Vector offset = pevTest.origin - self.GetOrigin();

        /*
        if (self.pev.spawnflags & SF_TRACKTRAIN_NOCONTROL)
            return false;
        */

        Math.MakeVectors(self.pev.angles);
        
        Vector local;
        local.x = DotProduct(offset, g_Engine.v_forward);
        local.y = -DotProduct(offset, g_Engine.v_right);
        local.z = DotProduct(offset, g_Engine.v_up);

        if (   local.x >= m_controlMins.x && local.y >= m_controlMins.y
            && local.z >= m_controlMins.z && local.x <= m_controlMaxs.x
            && local.y <= m_controlMaxs.y && local.z <= m_controlMaxs.z) {
            return true;
        }

        return false;
    }
    
    void StopSound() {
        if (m_soundPlaying != 0 && !string( self.pev.noise ).IsEmpty()) {
            g_SoundSystem.StopSound(self.edict(), CHAN_STATIC, self.pev.noise);
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, Boat::SOUND_BRAKE, m_flVolume, ATTN_NORM, 0, 100 );
        }

        m_soundPlaying = 0;
    }

    void UpdateSound() {
        if (string( self.pev.noise ).IsEmpty()) {
            return;
        }

        float flpitch = Boat::START_SND_PITCH + (abs(int(self.pev.speed)) * (Boat::MAX_SND_PITCH - Boat::START_SND_PITCH) / Boat::MAX_SND_SPEED);

        if (flpitch > 200)
            flpitch = 200;

        if (m_soundPlaying == 0) {
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, Boat::SOUND_BRAKE, m_flVolume, ATTN_NORM, 0, 100 );

            g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_STATIC, self.pev.noise, m_flVolume, ATTN_NORM, 0, int(flpitch));
            m_soundPlaying = 1;
        } else {
            g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_STATIC, self.pev.noise, m_flVolume, ATTN_NORM, SND_CHANGE_PITCH, int(flpitch));
        }
    }
    
    CBasePlayer@ GetDriver() {
        return m_pDriver;
    }
    
    void SetDriver( CBasePlayer@ pDriver ) {
        @m_pDriver = @pDriver;

        if( pDriver !is null ) {
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, Boat::SOUND_STARTON, 0.8, ATTN_NORM, 0, PITCH_NORM );
        }
    }
    
       // キー読み取り
    void AnalysisInput(CBasePlayer@ pPlayer, CBaseEntity@ pTrain) {    
        float vel = 0;
        int buttons = pPlayer.pev.button;
        
        if( ( buttons & IN_FORWARD )   != 0 ) { vel =  1;  pTrain.Use( pPlayer, pPlayer, USE_SET, vel ); }
        if( ( buttons & IN_BACK )      != 0 ) { vel = -1;  pTrain.Use( pPlayer, pPlayer, USE_SET, vel ); }
        if( ( buttons & IN_MOVELEFT )  != 0 ) { vel = 20;  pTrain.Use( pPlayer, pPlayer, USE_SET, vel ); }
        if( ( buttons & IN_MOVERIGHT ) != 0 ) { vel = 30;  pTrain.Use( pPlayer, pPlayer, USE_SET, vel ); }

        if (vel != 0)  {
            pPlayer.m_iTrain = TrainSpeed(int(pTrain.pev.speed), pTrain.pev.impulse);
            pPlayer.m_iTrain |= TRAIN_ACTIVE|TRAIN_NEW;
        }
    }
    
}

// 登録
void RegisterBoat() {
    g_CustomEntityFuncs.RegisterCustomEntity( "VehicleBoat",    Boat::ENT_NAME );
}


