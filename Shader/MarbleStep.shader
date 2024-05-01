Shader "Unlit/MarbleStep"
{
    Properties
    {
        _Contrast ("Contrast", Range(0, 100)) = 0.5
        _Offset     ("Offset", Range(-1, 1)) = 0.5
        _MaxDepth   ("Max Depth", Range(-10, 10)) = 2
        _MinDepth   ("Min Depth", Range(-10, 10)) = -2
        [MaterialToggle] _ClampDepth("Clamp Depth", Float) = 1
        _Steps     ("Steps", Range(1, 1000)) = 1
        _ColorOne ("ColorLight", Color) = (.25, .5, .5, 1)
        _ColorTwo ("ColorDark", Color) = (.25, .5, .5, 1)
        _ShadowColor ("ShadowColor", Color) = (.25, .5, .5, 1)
        _ShadowWeight ("Layer Shadow Amount", Range(0, 1)) = 0.5
        _ShadowNoiseChance ("Layer Shadow Noise", Range(0, 1)) = 0.5

        [MaterialToggle] _Debug("Debug Colors (Uncommnet Code Needed)", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        CULL Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile DEBUG_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv: TEXCOORD1;
                float  depth : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float  _Contrast;
            float  _Offset;
            float  _Steps;
            float4 _ColorOne;
            float4 _ColorTwo;
            float4 _ShadowColor;
            float _ShadowWeight;
            float _ShadowNoiseChance;
            float _Debug;
            float _ClampDepth;

            float _MinDepth;
            float _MaxDepth;

            // https://stackoverflow.com/a/4275343
            float rand(float2 uv) {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            v2f vert (appdata v)
            {
                v2f o;

                // Vertex position in world
                o.vertex = UnityObjectToClipPos(v.vertex);


                float3 cameraViewDirection = UNITY_MATRIX_IT_MV[2].xyz * _Offset;

                
                o.depth = mul(UNITY_MATRIX_IT_MV, v.vertex  + cameraViewDirection).z * _Contrast;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 col;

                // Normalize depth to be [0 - 1]
                
                i.depth = (i.depth - _MinDepth) / (_MaxDepth - _MinDepth);

        
            // UNCOMMENT FOR DEBUG COLORS
            // if (_Debug > 0.5) {
            //     float perc = frac(i.depth);
            //     if (i.depth < -1) { //Yellow

            //         col =  float4(1,1,0,1) * perc; 
            //         return col;
            //     }
            //     if (i.depth < 0) { //RED
            //         col =  float4(1,0,0,1)* perc;
            //         return col;
            //     }
            //     if (i.depth < 1) { //Green
            //         col = float4(0,1,0,1)* perc;
            //         return col;
            //     }
            //     if (i.depth > 1) { //Blue
            //         col = float4(0,0,1,1)* perc;
            //         return col;
            //     }
            // }

                // Force depth to be between 0 & 1. Will not show Dark or Light colors otherwise.
                // i.depth will be less than 0 possibly.
                if (_ClampDepth) {
                    i.depth = clamp(i.depth, 0, 1);
                }

                float depthScaled = i.depth * _Steps;

                // How close to a layer are we?
                float layerShadowAmount = frac(depthScaled);

                // Round depth to create layers
                i.depth = floor(depthScaled) / _Steps;

                // Base Color
                col = _ColorOne * i.depth +  _ColorTwo * (1 - i.depth);

                // Add Layer Shadows
                if (rand(i.uv) > _ShadowNoiseChance) {
                    col += col * (_ShadowColor * layerShadowAmount * _ShadowWeight);
                }

                return col;
            }
            ENDCG
        }
    }
}
