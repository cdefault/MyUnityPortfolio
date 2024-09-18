Shader "Unlit/NewUnlitShader"
{
    Properties
    {
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

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
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float3 palette(float t) {
                float3 a = float3(0.5, 0.5, 0.5);
                float3 b = float3(0.5, 0.5, 0.5);
                float3 c = float3(1.0, 1.0, 1.0);
                float3 d = float3(0.263,0.416,0.557);

                return a + b * cos( 6.28318 * (c * t + d));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 c;

                //half2 uv = (i.pos.xy * 2 - _ScreenParams.xy) / _ScreenParams.y;
                half2 uv = i.uv * 2 - 1;
                half2 uv0 = uv;
                half3 finalColor = 0;

                for (float i = 0; i < 4.0; ++i) {
                    uv = frac(uv * 1.5) - 0.5;
                    float d = length(uv) * exp(-length(uv0));
                    half3 col = palette(length(uv0) + i * 0.4 + _Time.y * 0.4);

                    d = sin(d * 8 + _Time.y) / 8;
                    d = abs(d);
                    
                    d = pow(0.01 / d, 1.2);
                    finalColor += col * d;
                }
                c = half4(finalColor * 0.5, 1.0);
                return c; 
            }
            ENDCG
        }
    }
}
