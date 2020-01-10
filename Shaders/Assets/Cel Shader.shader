Shader "Custom/Cel Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (0,0,0,1)
		_ShadowSharpness("Shadow Sharpness", Range(0, 1)) = 0.5
		_ShadowStrength("Min Shadow Darkness", Range(0, 1)) = 1
		_Outline("Outline", Float) = 0.1
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		_Shinyness ("Shinyness", Float) = 0.5
		_Normal("Normal", 2D) = "bump"{}
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
				float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
                float4 position : SV_POSITION;
				float3 worldNormal : TEXCOORD2;

				half3 xTangentToWorld : TEXCOORD4;
				half3 yTangentToWorld : TEXCOORD5;
				half3 zTangentToWorld : TEXCOORD6;

            };

			float4 _Color;
			float _ShadowSharpness;
			float _ShadowStrength;
			float _Outline;
			float4 _OutlineColor;
			sampler2D _MainTex;
			sampler2D _Normal;
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
				float3 tangent = UnityObjectToWorldDir(IN.tangent);
				float3 bitangent = cross(o.worldNormal, tangent.xyz) * IN.tangent.w;
				o.xTangentToWorld = half3(tangent.x, bitangent.x, o.worldNormal.x);
				o.yTangentToWorld = half3(tangent.y, bitangent.y, o.worldNormal.y);
				o.zTangentToWorld = half3(tangent.z, bitangent.z, o.worldNormal.z);
				o.uv = IN.uv;
                return o;
            }

			float4 frag(v2f IN) : SV_Target
			{
				// sample the texture
				float3 tangentNorm = normalize(UnpackNormal(tex2D(_Normal, IN.uv)));
				float3 worldNormal;
				worldNormal.x = dot(IN.xTangentToWorld, tangentNorm);
				worldNormal.y = dot(IN.yTangentToWorld, tangentNorm);
				worldNormal.z = dot(IN.zTangentToWorld, tangentNorm);
				worldNormal = normalize(worldNormal);
				//worldNormal = IN.worldNormal;
                float4 newColor = tex2D(_MainTex, IN.uv) * _Color;
				float4 DiffuseColor = GetDiffuse(worldNormal) * _LightColor0;

				newColor *= (DiffuseColor + GetSpecular(worldNormal, IN.worldPosition));

				float shadowAmount = 1 - GetDiffuse(worldNormal);

				//newColor *= 1 - GetOutline(IN.worldNormal, IN.worldPosition);
				//newColor += GetOutline(IN.worldNormal, IN.worldPosition) * _OutlineColor;
				return newColor;
            }
            ENDCG
        }
    }
}
