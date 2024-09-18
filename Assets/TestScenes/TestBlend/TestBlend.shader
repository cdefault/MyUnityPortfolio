Shader "Unlit/TestBlend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Src Blend", int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Dst Blend", int) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", int) = 2
        _Color("Color", color) = (1,1,1,1)
        _Intensity("Intensity", float) = 1
        _MainUVSpeedX("MainUV Speed X", float) = 0
        _MainUVSpeedY("MainUV Speed Y", float) = 0


    }
    SubShader
    {
        Tags{"Queue" = "Transparent"}
        Tags { "RenderType"="Transparent" }
        LOD 100
        Blend [_SrcBlend] [_DstBlend]
        Cull [_Cull]

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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Intensity;
            float _MainUVSpeedX;
            float _MainUVSpeedY;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex) + float2(_MainUVSpeedX, _MainUVSpeedY) * _Time.y;


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col = col * _Color * _Intensity;
                
                return col;
            }
            ENDCG
        }
    }
}
