Shader "Unlit/MarbleStep"
{
    Properties
    {
        [Header(DEPTH)]
        [Space(10)]
        _Contrast ("Contrast", Range(0, 100)) = 0.5
        _Offset     ("Offset", Range(-1, 1)) = 0.5
        _MaxDepth   ("Max Depth", Range(-10, 10)) = 2
        _MinDepth   ("Min Depth", Range(-10, 10)) = -2
        [MaterialToggle] _ClampDepth("Clamp Depth", Float) = 1
        [Toggle(DEBUG)] _Debug("Debug Colors (Compile Time)", int) = 1
        [Space(25)]

        [Header(SHADING)]
        [Space(10)]
        _Steps     ("Steps", Range(1, 1000)) = 1
        _ColorOne ("ColorLight", Color) = (.25, .5, .5, 1)
        _ColorTwo ("ColorDark", Color) = (.25, .5, .5, 1)
        _ShadowColor ("ShadowColor", Color) = (.25, .5, .5, 1)
        _ShadowWeight ("Layer Shadow Amount", Range(0, 1)) = 0.5
        _ShadowNoiseChance ("Layer Shadow Noise", Range(0, 1)) = 0.5

        [Toggle(ACCOUNT_VIEW_PITCH)] _ViewPitchInfluence_Toggle ("View Pitch Angle Influence Toggle", int) = 1
        _ViewPitchInfluence ("View Pitch Angle Influence", Range(0, 1)) = 1
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

            #pragma shader_feature DEBUG
            #pragma shader_feature ACCOUNT_VIEW_PITCH

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
            float _ClampDepth;
            float _ViewPitchInfluence;

            float _MinDepth;
            float _MaxDepth;

            // https://stackoverflow.com/a/4275343
            float rand(float2 uv) {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            float2 rotate2f(float2 v, float rads) {
                float c = cos(rads);
                float s = sin(rads);
                return float2(
                            (v.x * c) - (v.y * s),
                            (v.x * s) + (v.y * c));
            }

            float3x3 AngleAxis3x3(float angle, float3 axis)
            {
                float c, s;
                sincos(angle, s, c);

                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;

                return float3x3(
                    t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,
                    t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,
                    t * x * z - s * y,  t * y * z + s * x,  t * z * z + c
                );
            }

            v2f vert (appdata v)
            {

                v2f o;

                // Vertex position in world
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                float3 cameraModelViewDir  = UNITY_MATRIX_IT_MV[2].xyz;

// Make it s.t. the cameras pitch has no affect on how the model is rendered
#ifdef ACCOUNT_VIEW_PITCH
                // Get Right Vector in Camera-Model-Space
                float3 cameraModelRightDirection = UNITY_MATRIX_MV[0].xyz;

                // Get Camera Forward vector
                float3 cameraViewDir = UNITY_MATRIX_V[2].xyz;

                // Calculate Cameras pitch where a pitch of 0 signifies the cameras view is parrallel to the floor.
                float pitchDiff = _ViewPitchInfluence * acos(mul((float3x3)UNITY_MATRIX_V, float3(0,1,0)).y);

                // Account if camera is looking up or down
                pitchDiff *= cameraViewDir.y < 0 ? -1 : 1;

                // Rotate model s.t. it would appear to the camera as it would if the cameras pitch was 0.
                float3x3 modelRotMat = AngleAxis3x3(pitchDiff, cameraModelRightDirection);
                o.depth = mul(UNITY_MATRIX_IT_MV, mul(modelRotMat, v.vertex)  + (cameraModelViewDir * _Offset)).z * _Contrast;
#else
                // Calculate depth to vertex in a Camera-Model-Space; need to account for both of their rotaion, position, and scale
                o.depth = mul(UNITY_MATRIX_IT_MV, v.vertex  + (cameraModelViewDir * _Offset)).z * _Contrast;
#endif
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 col;

                // Normalize depth to be [0 - 1]
                i.depth = (i.depth - _MinDepth) / (_MaxDepth - _MinDepth);

// Show debug colors to help understand how contrast, offset, mindepth, and max depth influence output   
#if DEBUG
                float perc = frac(i.depth);
                if (i.depth < -1) { //Yellow

                    col =  float4(1,1,0,1) * perc; 
                    return col;
                }
                if (i.depth < 0) { //RED
                    col =  float4(1,0,0,1)* perc;
                    return col;
                }
                if (i.depth < 1) { //Green
                    col = float4(0,1,0,1)* perc;
                    return col;
                }
                if (i.depth > 1) { //Blue
                    col = float4(0,0,1,1)* perc;
                    return col;
                }
#endif

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

                // Add Layer Shadows & Shadow Noise
                if (rand(i.uv) > _ShadowNoiseChance) {
                    col += col * (_ShadowColor * layerShadowAmount * _ShadowWeight);
                }

                return col;
            }
            ENDCG
        }
        
    }
    CustomEditor "MarbleStepGUI"
}
