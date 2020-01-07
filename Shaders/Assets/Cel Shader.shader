Shader "Custom/Cel Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (0,0,0,1)
		_ShadowSharpness("Shadow Sharpness", Range(0, 1)) = 0.5
		_ShadowStrength("Max Shadow Darkness", Range(0, 1)) = 1
		_Outline("Outline", Float) = 0.1
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		_Shinyness ("Shinyness", Float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"  "LightMode"="ForwardBase" "Queue" = "Transparent"}

		Pass
		{
		ZWrite Off
			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

            struct appdata
            {
                float4 position : POSITION;
				float3 normal : NORMAL;
            };

            struct v2f
            {
				float3 normal : TEXCOORD1;
                float4 position : SV_POSITION;
            };
			float _Outline;
			float4 _OutlineColor;

            v2f vert (appdata IN)
            {
                v2f o;
				o.normal = normalize(IN.normal);
				o.position = IN.position;
				o.position += float4(o.normal * _Outline, 0);
				o.position = UnityObjectToClipPos(o.position);
                return o;
            }

            float4 frag (v2f IN) : SV_Target
            {
				float4 newColor = _OutlineColor;
				return newColor;
            }
            ENDCG
		}
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

            struct appdata
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float4 worldPosition : TEXCOORD2;
                float4 position : SV_POSITION;

            };

			float4 _Color;
			float _ShadowSharpness;
			float _ShadowStrength;
			float _Outline;
			float4 _OutlineColor;
			sampler2D _MainTex;
			float _Shinyness;

			float GetDiffuse(float3 worldNormal)
			{
				float diffuseAmount = smoothstep(-_ShadowSharpness, _ShadowSharpness, dot(_WorldSpaceLightPos0, worldNormal));
				float shadowLimiter =  step(_ShadowStrength, diffuseAmount);
				diffuseAmount *= shadowLimiter;
				diffuseAmount += (1 - shadowLimiter) * _ShadowStrength;
				return diffuseAmount;
			}

			float GetSpecular(float3 worldNormal, float4 position)
			{
				float3 dirToCam = normalize(_WorldSpaceCameraPos.xyz - position.xyz);
				float3 reflectedLightDir = reflect(normalize(-_WorldSpaceLightPos0), worldNormal);
				float specularity = max(0, dot(reflectedLightDir, dirToCam));
				specularity = pow(specularity, _Shinyness);
				return specularity;
			}

			float GetOutline(float3 worldNormal, float4 position)
			{
				float3 cameraForward = normalize(_WorldSpaceCameraPos - position.xyz);
				float outlineAmount = dot(worldNormal, cameraForward);
				outlineAmount = 1 - step(_Outline, outlineAmount);
				return outlineAmount;
			}

            v2f vert (appdata IN)
            {
                v2f o;
                o.position = UnityObjectToClipPos(IN.position);
				o.worldPosition = mul(unity_ObjectToWorld, IN.position);
				o.worldNormal = UnityObjectToWorldNormal(IN.normal);
				o.uv = IN.uv;
                return o;
            }

            float4 frag (v2f IN) : SV_Target
            {
                // sample the texture
                float4 newColor = tex2D(_MainTex, IN.uv) * _Color;
				float4 DiffuseColor = GetDiffuse(IN.worldNormal) * _LightColor0;

				newColor *= (DiffuseColor + GetSpecular(IN.worldNormal, IN.worldPosition));

				float shadowAmount = 1 - GetDiffuse(IN.worldNormal);

				//newColor *= 1 - GetOutline(IN.worldNormal, IN.worldPosition);
				//newColor += GetOutline(IN.worldNormal, IN.worldPosition) * _OutlineColor;
				return newColor;
            }
            ENDCG
        }
    }
}
