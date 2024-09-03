Shader "Unlit/BurningDissolve"
{
    Properties
    {
        [Header(Base)]
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}

        [Space(10)]
        [Header(Dissolve)]
        _DissolveTex("Dissolve Texture", 2D) = "white" {}
        [NoScaleOffset]_BurnTex("BurnTexture Texture", 2D) = "white" {}
        [HideInInspector]_Clip("Clip", Range(-0.1, 1)) = 0
        
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


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;
            sampler _BurnTex;
            fixed _Clip;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = float2(v.uv.x, -v.uv.y);
                o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv.xy);
                
                fixed4 dissolveTex = tex2D(_DissolveTex, i.uv.zw);
                _Clip = frac(_Time * 3) - 0.1;
                clip(dissolveTex.r - _Clip);

                float dissolveValue = saturate((dissolveTex.r - _Clip) / (_Clip + 0.1 - _Clip));
                fixed4 burnTex = tex1D(_BurnTex, dissolveValue);

                col += burnTex;
                return col;
            }
            ENDCG
        }
    }
}
