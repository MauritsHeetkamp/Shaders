Shader "Lit/Diffuse With Shadows"
{
    Properties
    {
        [NoScaleOffset] _MainTex("Texture", 2D) = "white" {}
    }
        SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

        // compile shader into multiple variants, with and without shadows
        // (we don't care about any lightmaps yet, so skip these variants)
        #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
        // shadow helper functions and macros
        #include "AutoLight.cginc"

        struct v2f
        {
            float2 uv : TEXCOORD0;
            SHADOW_COORDS(1) // put shadows data into TEXCOORD1
            float4 pos : SV_POSITION;
        };
        v2f vert(appdata_base v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            // compute shadows data
            TRANSFER_SHADOW(o)
            return o;
        }

        sampler2D _MainTex;

        fixed4 frag(v2f i) : SV_Target
        {
         fixed4 col = tex2D(_MainTex, i.uv);
        fixed shadow = SHADOW_ATTENUATION(i);
        fixed3 lighting = shadow;
        col.rgb *= lighting;
        return col;
    }
    ENDCG
}

// shadow casting support
UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}