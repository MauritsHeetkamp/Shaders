Shader "Custom/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		_Coloro ("Whitener", Color) = (1,1,1,1)
		_Noise ("Noise", float) = 1
		_MinimalHighlightValue("Minimal Extra Highlight Value", Range(0, 2)) = 0.5
		_Size("Size", float) = 3
		_WaveHeight("Wave Height", Range(0, 1)) = 0.5
    }
    SubShader
    {
		Pass
		{
			CGPROGRAM
				#pragma vertex vertexFunction
				#pragma fragment fragmentFunction
				#include "UnityCG.cginc"

				struct VERTINPUT
				{
					float4 position : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct FRAGINPUT
				{
					float4 position : POSITION;
					float2 uv : TEXCOORD0;
					float3 worldPos : TEXCOORD1;
					float4 screenPos : TEXCOORD2;
				};

				
				 float random (float2 uv)
				{
					return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
				}
				float _Size;
				float4 _Color; //sea
				float4 _Coloro; //whiter part of sea
				float _CellSize; //Size of the cells
				float _Noise; //Randomness of moving points
				float _MinimalHighlightValue; //Minimal value(0, 1) to apply the brightest highlight
				float _WaveHeight;
				sampler2D _CameraDepthTexture;
				

				float WorleyNoise(float3 worldPos)
				{
					float2 worldPosition = float2(worldPos.x, worldPos.z) * _Size;
					//NOISE GENERATION
					float2 pixelLocation = frac(worldPosition);
					float2 gridTileIndex = floor(worldPosition);
					float2 target = float2(gridTileIndex + pixelLocation);

					float closestDistance = 100;

					for(int x = -1; x <= 1; x++)
					{
						for(int y = -1; y <= 1; y++)
						{
							float2 thisPoint = gridTileIndex + float2(x, 0) + float2(0, y);
							thisPoint += float2(random(thisPoint), random(thisPoint));
							thisPoint +=0.3*sin(_Time.y + _Noise*thisPoint);
							float distancee = distance(target, thisPoint);
							closestDistance = min(closestDistance, distancee);
						}
					}
					return closestDistance;
				}

				FRAGINPUT vertexFunction(VERTINPUT IN)
				{
					FRAGINPUT holder;
					holder.position = UnityObjectToClipPos(IN.position);
					holder.uv = IN.uv;
					holder.worldPos = mul (unity_ObjectToWorld, IN.position);
					holder.position += float4(0, WorleyNoise(holder.worldPos + float3(_Noise, 0, _Noise)) * _WaveHeight, 0, 0);
					holder.screenPos = ComputeScreenPos(holder.position);
					return holder;
				}

				float4 fragmentFunction(FRAGINPUT IN) : SV_TARGET
				{
					float closestDistance = WorleyNoise(IN.worldPos);
					closestDistance = clamp(closestDistance, 0.3, 1);
					float extraHighlights = step(_MinimalHighlightValue, closestDistance);
					//COLORING IN
					float4 newColor = _Color;
					newColor += mul(closestDistance, _Coloro);
					newColor += mul(extraHighlights, _Coloro);

					float2 uvPosition = IN.screenPos.xy / IN.screenPos.w;
					float4 yes = tex2D(_CameraDepthTexture, uvPosition);
					float eyeDepth = Linear01Depth(yes);
					newColor *= eyeDepth;
					return newColor;
				}
			ENDCG
		}
	}
}

