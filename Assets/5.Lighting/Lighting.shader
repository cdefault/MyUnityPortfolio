Shader "Portfolio/Lighting"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _Metallic("Metallic",Range(0,1)) = 0
    	
    	[Header(Cut Off)]
    	[Toggle(_ENABLE_CUTOFF)]_EnableMask("Enable Cut Off",Float) = 0
        _Cutoff("Cut off",Range(0,1)) = 0
        
        [Header(Specular)]
        _Smoothness("_Smoothness",Range(0.1,2)) = 0.5
    	
        [Header(Emission)]
        [HDR]_Emission("_Emission",Color) = (0, 0, 0, 0)
    	
    	[Header(Normal Map)]
    	_NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalMapIntensity ("Normal Map Intensity", Float) = 1
        
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
        	Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma multi_compile _ SHADOWS_SCREEN
            #pragma multi_compile _ _ENABLE_CUTOFF
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 color : COLOR;
            	// ��ȡ����
            	float4 tangent : TANGENT;
            	#if defined(LIGHTMAP_ON)
					float2 lightmapUV : TEXCOORD1;
				#endif
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 objectPos : TEXCOORD3;
            	// �洢����
                float4 tangent: TEXCOORD4;
            	SHADOW_COORDS(5)
            	#if defined(LIGHTMAP_ON)
					float2 lightmapUV : TEXCOORD6;
				#endif
            	
            	
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            float4 _MainTex_ST;
            half4 _Color;
            half4 _Emission;

            half _Smoothness
        ;
            half _Metallic;
            half _Cutoff;
            half _NormalMapIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
            	// ����ת��������ռ�
            	o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.objectPos = v.vertex;
            	#if LIGHTMAP_ON
					o.lightmapUV = v.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
            	// ���㶥��λ������Ӱ��ͼ�ϵ�����
            	TRANSFER_SHADOW(o);
                return o;
            }

            half3 GetNormalMap(float3 normal, float4 tangent, float2 uv, float intensity,bool invertY)
            {
            	// ���㸱����
	            float3 bitangent = cross(normal, tangent) * tangent.w;
            	float3 normalMap = UnpackScaleNormal(tex2D(_NormalMap, uv.xy), intensity);
            	float3 newNormal = normalize(
											normalMap.x * tangent +
											normalMap.y * (invertY?-1:1) * bitangent +
											normalMap.z * normal
									);
            	return newNormal;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // float3 normal = normalize(i.normal);
            	
                #if _INVERT_NORMAL_Y
                float3 normal = GetNormalMap(i.normal,i.tangent,i.uv,_NormalMapIntensity,true);
                #else
                float3 normal = GetNormalMap(i.normal, i.tangent, i.uv, _NormalMapIntensity, false);
                #endif
            	
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
            	//������Ӱ
            	fixed shadow = SHADOW_ATTENUATION(i);

            	// ������
            	float3 shLighting = ShadeSH9(float4(normal, 1));

            	//����Lightmap
				#if LIGHTMAP_ON
					float3 lightMap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));
				#endif

                
                // ������
                half4 albedo = tex2D(_MainTex,i.uv) * _Color + half4(_Emission.rgb,0);
                half3 specularColor; 
				float invertReflectivity; 
				albedo.rgb = DiffuseAndSpecularFromMetallic(
					albedo.rgb, _Metallic, specularColor, invertReflectivity
				);
                albedo.rgb *= 1- _Metallic;
                half diffuse = saturate(dot(normal,lightDir));
            	// ����ӰԼ����ǿ
            	#if LIGHTMAP_ON
            		half3 diffuseFinal = albedo * lightMap;
				#else
					half3 diffuseFinal = diffuse * albedo * _LightColor0.rgb * shadow;
				#endif
                

            	
                half3 ambient = (shLighting) * albedo ;

                // �߹ⷴ��
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfVector = normalize(lightDir+viewDir);
                half specular = pow(max(0,dot(normal, halfVector)), _Smoothness*100);
            	// ����ӰԼ����ǿ
            	
                half3 specularFinal = specular * specularColor * _LightColor0.rgb * shadow;
				
            	
                
                #ifdef _ENABLE_CUTOFF
            	clip(albedo.a-_Cutoff);
            	#endif
            	// �������� + ������ + �߹⣩
                return half4((ambient +  diffuseFinal + specularFinal)  , albedo.a);                
            }
            ENDCG
        }
    	
    	Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend One One
            CGPROGRAM
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile _ SHADOWS_SCREEN
            #pragma multi_compile _ _ENABLE_CUTOFF
            #pragma multi_compile _ LIGHTMAP_ON
            
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            	float2 lightmapUV : TEXCOORD1;
                float3 normal : NORMAL;
                float3 color : COLOR;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 objectPos : TEXCOORD3;
            	SHADOW_COORDS(4)
            	#if LIGHTMAP_ON
					float2 lightmapUV : TEXCOORD5;
				#endif
            	
            	
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;
            half4 _Emission;

            half _Smoothness
        ;
            half _Metallic;
            half _Cutoff;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.objectPos = v.vertex;
            	#if LIGHTMAP_ON
					o.lightmapUV = v.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
            	// ���㶥��λ������Ӱ��ͼ�ϵ�����
            	TRANSFER_SHADOW(o);
            	
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                float3 normal = normalize(i.normal);
            	
            	// �ƹ�
            	#ifdef DIRECTIONAL
					float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					float3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
				#endif

            	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
            	float3 lightCol = _LightColor0.rgb  * attenuation;
            	
                // ������
                half4 albedo = tex2D(_MainTex,i.uv) * _Color + half4(_Emission.rgb,0);
                half3 specularColor; 
				float invertReflectivity; 
				albedo.rgb = DiffuseAndSpecularFromMetallic(
					albedo.rgb, _Metallic, specularColor, invertReflectivity
				);
                albedo.rgb *= 1- _Metallic;
                half diffuse = saturate(dot(normal,lightDir));
            	// ����ӰԼ����ǿ
                half3 diffuseFinal = diffuse * albedo * lightCol;

                // �߹ⷴ��
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfVector = normalize(lightDir+viewDir);
                half specular = pow(max(0,dot(normal, halfVector)), _Smoothness*100);
            	// ����ӰԼ����ǿ
                half3 specularFinal = specular * specularColor * lightCol;
            	

            	
                
                #ifdef _ENABLE_CUTOFF
            	clip(albedo.a-_Cutoff);
            	#endif
            	// ���ӵƹ��ϲ���Ҫ����ӻ�����
                return half4((diffuseFinal + specularFinal)  , albedo.a);                
            }
            ENDCG
		}
    	
        
        Pass {
			Tags {
				// ����Unity�����Pass������������Ӱ��
				"LightMode" = "ShadowCaster"
			}
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile _ _ENABLE_CUTOFF
			
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			struct appdata {
				float4 position : POSITION;
            	float3 normal : NORMAL;
            	float2 uv : TEXCOORD0;
			};

			struct v2f
            {
				#ifdef _ENABLE_CUTOFF
                float2 uv : TEXCOORD0;
				#endif
                float4 position : SV_POSITION;
            };

			sampler2D _MainTex;
            float4 _MainTex_ST;
			half _Cutoff;
			
			v2f vert(appdata v) {
				v2f o;
				o.position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
				#ifdef _ENABLE_CUTOFF
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				#endif
				return o;
			}
			half4 frag (v2f i) : SV_Target {
				#ifdef _ENABLE_CUTOFF
				// ���в���Ҫ����
				clip(tex2D(_MainTex,i.uv).a - _Cutoff);
				#endif
				return 0;
			}
			
			ENDCG
        }
    	
    	Pass {
			Tags {
				"LightMode" = "Meta"
			}

			Cull Off

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityPBSLighting.cginc"
			#include "UnityMetaPass.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			half4 _Color;

			half _Smoothness;
			half _Metallic;
			half _Cutoff;
			half4 _Emission;
			sampler2D _GIAlbedoTex;
            float4 _GIAlbedoColor;

			
			

			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			

			float3 GetAlbedo (v2f i) {
				float3 albedo = tex2D(_MainTex, i.uv).rgb * _Color;
				return albedo;
			}

			float GetMetallic (v2f i) {
				return _Metallic;
			}

			float GetSmoothness (v2f i) {
				return _Smoothness;
			}

			float3 GetEmission (v2f i) {
				return _Emission;
			}

			v2f vert (appdata v) {
				v2f i;
				i.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return i;
			}

			float4 frag (v2f i) : SV_TARGET {
				UnityMetaInput o;
				UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
                fixed4 c = tex2D (_GIAlbedoTex, i.uv);
				float oneMinusReflectivity;
				float3 albedo = DiffuseAndSpecularFromMetallic(
					GetAlbedo(i), GetMetallic(i),
					o.SpecularColor, oneMinusReflectivity
				);
                o.Albedo = float3(c.rgb * _GIAlbedoColor.rgb) * albedo;
				float roughness = SmoothnessToRoughness(GetSmoothness(i)) * 0.5;
				o.Albedo += o.SpecularColor * roughness;
                o.Emission = GetEmission(i);
                return UnityMetaFragment(o);
			}


			ENDCG
		}
        
        
    }
}