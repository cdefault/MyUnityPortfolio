Shader "Hidden/PostProcessing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //_Value("Value", float) = 0.5
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"


            sampler2D _MainTex;
            float _Value;

            fixed4 frag (v2f_img i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                col = step(_Value, col);
                return col;
            }
            ENDCG
        }
    }
}
