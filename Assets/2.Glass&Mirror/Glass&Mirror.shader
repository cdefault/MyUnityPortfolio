Shader "Unlit/Glass&Mirror"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(Mirror, Glass)]_MirrorOrGlass("MirrorOrGlass", int) = 0
        
        [Toggle]_EnableNormalTex("EnableNormalTex", int) = 1
        [Normal]_NormalTex("NormalTex", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _MIRRORORGLASS_MIRROR _MIRRORORGLASS_GLASS
            #pragma multi_compile _ _ENABLENORMALTEX_ON


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                #if _ENABLENORMALTEX_ON
                float4 tangent : TANGENT;
                #endif
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 localPos : TEXCOORD1;
                float3 worldPos: TEXCOORD2;
                float3 worldNormal : TEXCOORD3;

                #if _ENABLENORMALTEX_ON
                //用于传递张成切线空间的基向量TBN
                float3 worldTangent:TEXCOORD4;
                float3 worldBitangent:TEXCOORD5;
                #endif

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _MirrorOrGlass;

            sampler2D _NormalTex;
            float4 _NormalTex_ST;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.localPos = v.vertex.xyz;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _NormalTex);

                #if _ENABLENORMALTEX_ON
                o.worldTangent = UnityObjectToWorldDir(v.tangent);
                //w为OpenGL和DX的正负性标记
                o.worldBitangent = cross(o.worldNormal, o.worldTangent) * v.tangent.w;
                #endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);

                #if _ENABLENORMALTEX_ON
                //取得切线空间内的法线向量
                fixed3 normalMap = UnpackNormal(tex2D(_NormalTex, i.uv));
                //用切线空间的三个基在世界空间的表示分别乘原空间内的向量即可转换到世界空间
                normal = normalize(normalMap.x * i.worldTangent + normalMap.y * i.worldBitangent + normalMap.z * i.worldNormal);
                #endif

                fixed3 V = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 N = normal;
                fixed3 R;
                #if _MIRRORORGLASS_MIRROR
                    R = reflect(-V, N);
                #elif _MIRRORORGLASS_GLASS
                    float ratio = 1.00 / 1.52;
                    R = refract(-V, N, ratio);
                #endif
                

                half4 cubemap = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, R);
                half3 col = DecodeHDR(cubemap, unity_SpecCube0_HDR);


                return half4(col, 1);
            }
            ENDCG
        }
    }
}
