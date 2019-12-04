Shader "Custom/EpicShader"
{
	Properties
	{
		_MainTexture ("MainTexture", 2D) = "white" {}
		_SnowColor ("SnowColor", Color) = (1,1,1,1)
		_Color ("Color", Color) = (1,1,1,1)
		_Size ("Size", Range(-1, 1)) = 1
		_SnowNormal("Minimal Snow Normal", Vector) = (0,1,0)
		_SnowPercentage("Snow Removal Amount", Range(0.00001, 1.5)) = 1
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM
				#pragma vertex vertexFunction
				#pragma fragment fragmentFunction

				#include "UnityCG.cginc"

				struct v2f
				{
					float4 renderPosition : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : NORMAL;
				};

				struct VertexData
				{
					float4 position: POSITION;
					float2 uv: TEXCOORD0;
					float3 normal : NORMAL;
				};

				sampler2D _MainTexture;
				float4 _Color;
				float4 _SnowColor;
				float _Size;
				float3 _SnowNormal;
				float _SnowPercentage;

				v2f vertexFunction(VertexData IN)
				{
					v2f holder;
					holder.renderPosition = UnityObjectToClipPos(IN.position);
					holder.uv = IN.uv;
					holder.normal = IN.normal;
					return holder;
				}

				void Hi()
				{
				
				}

				float4 fragmentFunction(v2f IN) : SV_Target
				{
					float4 color = tex2D(_MainTexture, IN.uv);

					//Calculate Snow
					float3 wantedNormal = _SnowNormal;

					float snowAmount = dot(wantedNormal, IN.normal);
					snowAmount = max(0, snowAmount);
					snowAmount = step(_SnowPercentage, snowAmount);

					color -= color * snowAmount;

					color += snowAmount;

					return color;
				}
			ENDCG
		}
	}
}