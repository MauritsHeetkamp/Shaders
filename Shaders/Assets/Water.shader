Shader "Custom/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		_Coloro ("Whitener", Color) = (1,1,1,1)
		_WaterOpacity("Water Opacity", Range(0, 1)) = 1
		_Noise ("Noise", float) = 1
		_MinimalHighlightValue("Minimal Extra Highlight Value", Range(0, 2)) = 0.5
		_Size("Size", float) = 3
		_FoamMultiplier("Foam Multiplier", float) = 1
		_WaveHeight("Wave Height", Range(0, 2)) = 0.5
		_DepthMultiplier("Depth Multiplier", float) = 1
		_DepthColor("Depth Color", float) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0
    }
    SubShader
    {
		Tags {"Queue" = "Transparent" "RenderType"="Transparent" "LightMode"="ForwardBase"}
		ZWrite Off
		Blend  SrcAlpha OneMinusSrcAlpha
		Pass
		{
			CGPROGRAM
				#pragma vertex vertexFunction
				#pragma fragment fragmentFunction
				#include "UnityCG.cginc"
				#include "Lighting.cginc"

				struct VERTINPUT
				{
					float4 position : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : NORMAL;
				};

				struct FRAGINPUT
				{
					float4 position : POSITION;
					float2 uv : TEXCOORD0;
					float4 worldPos : TEXCOORD1;
					float4 screenPos : TEXCOORD2;
					float3 normal: TEXCOORD3;
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
				float _FoamMultiplier;
				float _WaterOpacity;
				float _DepthMultiplier;
				float _DepthColor;
				float _Smoothness;
				

				float WorleyNoise(float4 worldPos)
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

				float GetDiffuse(float3 worldNormalDir)
				{
					float diffuseAmount = max(0, dot(_WorldSpaceLightPos0, worldNormalDir));
					return diffuseAmount;
				}

				float GetSpecular(float3 worldNormalDir, float4 position)
				{
					float reflectAmount;

					float3 camNormal = normalize(_WorldSpaceCameraPos - position.xyz);
					float3 lightNormal = normalize(-_WorldSpaceLightPos0);
					lightNormal = reflect(lightNormal, worldNormalDir);
					reflectAmount = pow(max(0,dot(camNormal, lightNormal)), 32);

					return reflectAmount;
				}

				float3 GetReflection(float3 worldNormalDir, float4 position)
				{
					float3 camNormal = normalize(position.xyz - _WorldSpaceCameraPos);
					float3 viewReflection = reflect(camNormal, worldNormalDir);

					float4 environmentData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, viewReflection);
					return environmentData.rgb;
				}
				float3 GetRefraction(float3 worldNormalDir, float4 position)
				{
					float3 camNormal = normalize(position.xyz - _WorldSpaceCameraPos);
					float3 viewReflection = refract(camNormal, worldNormalDir, 1.333);

					float4 environmentData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, viewReflection);
					return environmentData.rgb;
				}

				FRAGINPUT vertexFunction(VERTINPUT IN)
				{
					FRAGINPUT holder;
					holder.position = UnityObjectToClipPos(IN.position);
					holder.uv = IN.uv;
					holder.worldPos = mul (unity_ObjectToWorld, IN.position);
					holder.position -= float4(0, WorleyNoise(holder.worldPos + float4(_Noise, 0, _Noise, 0)) * _WaveHeight, 0, 0);
					holder.screenPos = ComputeScreenPos(holder.position);
					holder.normal = UnityObjectToWorldNormal(IN.normal);
					return holder;
				}

				float4 fragmentFunction(FRAGINPUT IN) : SV_TARGET
				{
					//COLORING IN WATER
					float4 newColor = float4(0,0,0,0);
					
					float4 waterColor = _Color;
					float closestDistance = WorleyNoise(IN.worldPos);
					closestDistance = clamp(closestDistance, 0.3, 1);
					float extraHighlights = step(_MinimalHighlightValue, closestDistance);
					waterColor += mul(closestDistance, _Coloro);
					waterColor += mul(extraHighlights, _Coloro);

					float2 uvPosition = IN.screenPos.xy / IN.screenPos.w;
					float4 yes = tex2D(_CameraDepthTexture, uvPosition);
					float eyeDepth = LinearEyeDepth(yes).r;

					float shoreLine = 1 - saturate(_FoamMultiplier * (eyeDepth - IN.screenPos.w));
					float depthDarkener = saturate(_DepthMultiplier * (eyeDepth - IN.screenPos.w));
					waterColor += shoreLine;
					waterColor -= _DepthColor * depthDarkener;

					float4 reflectionColor = float4(GetReflection(IN.normal, IN.worldPos), 1) * _Smoothness;
					float diffuseAmount = GetDiffuse(IN.normal);
					float specularAmount = GetSpecular(IN.normal, IN.worldPos);

					newColor = waterColor;
					newColor += reflectionColor;
					newColor += float4(specularAmount, specularAmount, specularAmount, 0);
					newColor *= diffuseAmount;

					newColor.a = _WaterOpacity;
					return newColor;
				}
			ENDCG
		}
	}
}

