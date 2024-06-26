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
        [Toggle(SOFT_DRIVE)] _SoftClamp_Toggle ("Enable Drive Clamping (Compile)", int) = 1
        _SoftClampPower ("Soft Clamp Power", Range(0, 10)) = 0
        [Toggle(DEBUG)] _Debug("Debug Colors (Compile)", int) = 1
        [Space(25)]

        [Header(SHADING)]
        [Space(10)]
        _Steps     ("Steps", Range(1, 1000)) = 1
        _ColorOne ("ColorLight", Color) = (.25, .5, .5, 1)
        _ColorTwo ("ColorDark", Color) = (.25, .5, .5, 1)
        _ShadowColor ("ShadowColor", Color) = (.25, .5, .5, 1)
        _ShadowWeight ("Layer Shadow Amount", Range(0, 1)) = 0.5
        _ShadowNoiseChance ("Layer Shadow Noise", Range(0, 1)) = 0.5

        [Header()]
        [Toggle(ACCOUNT_VIEW_PITCH_ROLL)] _ViewPitchInfluence_Toggle ("Ignore view roll & pitch (Compile)", int) = 1
        [Space(10)]

        [Toggle(FILM_GRAIN)] _FilmGrain_Toggle ("Enable Film Grain (Compile)", int) = 1
        _FilmGrainIntensity ("Grain Intensity", Range(0, 1)) = 0.5
        _FilmGrainColor ("Grain Color", Color) = (.25, .5, .5, 1)

        


        [Header(Color Adjust)]
        [Space(10)]
        _Saturation ("Saturation", Range(0, 2)) = 1
        _Value      ("Value", Range(0, 5)) = 1

        [Header(GLITCH)]
        [Space(10)]
        [Toggle(GLITCH)] _GLITCH_TOGGLE ("Enable Glitch Effect (Compile)", int) = 0
        _GlitchSize ("Glitch Size", Range(1, 60)) = 15
        _GlitchShiftAmount ("Glitch Shift Amount", Range(0, 10)) = 1
        _GlitchChance ("Glitch Chance", Range(0.9, 1.0)) =  0.993
        _GlitchColor ("Glitch Color", Color) = (.0, 1, .0, 1)

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
            #pragma shader_feature ACCOUNT_VIEW_PITCH_ROLL

            #pragma shader_feature FILM_GRAIN
            #pragma shader_feature SOFT_DRIVE
            #pragma shader_feature GLITCH

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv: TEXCOORD1;
                float  depth : DEPTH;
                float2 screenPos :TEXCOORD2;
#ifdef GLITCH
                float glitch : TEXCOORD3;
#endif
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

            float _MinDepth;
            float _MaxDepth;

            float _FilmGrainIntensity;
            float4 _FilmGrainColor;

            float _SoftClampPower;
            float _Saturation;
            float _Value;

            float _GlitchSize;
            float _GlitchChance;
            float _GlitchShiftAmount;
            float4 _GlitchColor;

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

            inline float3 projectOnPlane( float3 vec, float3 normal )
            {
                // Assumes normal is normalized
                return vec - normal * dot( vec, normal );
            }

            // float4 createPlane(float3 normal, float3 position) 
            // {
            //     return float4(
            //         normal.x,
            //         0,
            //         normal.z,
            //         (normal.x * (-position.x)) - (0 * position.y) - (normal.z * position.z)
            //     );

            // }

            // float distToPlane(float3 pos, float4 plane)
            // {
            //     return abs((plane.x * pos.x) + (plane.y * pos.y) + (plane.z * pos.z) + plane.w ) / sqrt((plane.x * plane.x) + (plane.y * plane.y) + (plane.z * plane.z));
            // }

            v2f vert (appdata v)
            {
               
                v2f o;

#ifdef GLITCH
                o.glitch = 0;
                //Vertex position in world
                float4 modelPos = mul(UNITY_MATRIX_MV, v.vertex);
                float factor = _GlitchSize * sin(_Time.x*1000);
                if (rand(float2(floor(modelPos.x * factor)/factor, _Time.x)) > _GlitchChance) {
                    v.vertex.xyz += UNITY_MATRIX_MV[1].xyz *  sin(_Time.x/10) * sin(_Time.w * 10 + modelPos.x)/7 * _GlitchShiftAmount;
                    //v.vertex.xyz += UNITY_MATRIX_MV[0].xyz *  sin(_Time.x/10) * sin(_Time.w * 10 + modelPos.x)/7;
                    o.glitch=1;
                }
#endif

                o.vertex    = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                
                float3 cameraModelViewDir  = UNITY_MATRIX_IT_MV[2].xyz;

                // TODO: FORCE DEPTH INTO BELL CURVE, MAKE IT NOT LINEAR

// Make it s.t. the cameras pitch has no affect on how the model is rendered
#ifdef ACCOUNT_VIEW_PITCH_ROLL

                float4x4 it_mv = UNITY_MATRIX_IT_MV;

                // Remove roll from right basis vector
                it_mv[0].y = 0;
                it_mv[0].xyz = normalize(it_mv[0].xyz);

                // Remove pitch & roll from up basis vector
                it_mv[1].xz = 0;
                it_mv[1].y  = 1;

                // Remove pitch from forward basis vector
                it_mv[2].y = 0;
                it_mv[2].xyz = normalize(it_mv[3].xyz);

                // Copy position of object
                it_mv[3].xyz = UNITY_MATRIX_M[3].xyz;

                cameraModelViewDir = it_mv[2].xyz;

                o.depth = mul(it_mv, v.vertex + (cameraModelViewDir * _Offset)).z * _Contrast;
#else
                // Calculate depth to vertex in a Camera-Model-Space; need to account for both of their rotaion, position, and scale
                o.depth = mul(UNITY_MATRIX_IT_MV, v.vertex  + (cameraModelViewDir * _Offset)).z * _Contrast;
#endif

                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                static const float PI = 3.141592653589793238462643383279502884197;
                static const float E  = 2.718281828459045;

                fixed4 col;

                // Normalize depth to be [0 - 1]
                i.depth = (i.depth - _MinDepth) / (_MaxDepth - _MinDepth);

#if SOFT_DRIVE
                i.depth = (2 / (1 + pow(E, -i.depth * _SoftClampPower))) - 1;
#endif


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

#ifdef FILM_GRAIN
                float4 grain = _FilmGrainColor * _FilmGrainIntensity * frac( 10000 * sin ((i.screenPos.x + i.screenPos.y * _Time.z * 100) * PI));
                col += grain; 
#endif

                float greyscale = dot(col, fixed3(.222, .707, .071));  // Convert to greyscale numbers with magic luminance numbers
                col.xyz = lerp(float3(greyscale, greyscale, greyscale), col.xyz, _Saturation);
                
                
                col.xyz *= _Value;
#ifdef GLITCH
                if (i.glitch == 1) {
                    return col += _GlitchColor * frac( 10000 * sin ((i.screenPos.x + i.screenPos.y * _Time.z * 100) * PI)) / 2;
                }
#endif
                return col;
            }
            ENDCG
        }
        
    }
    CustomEditor "MarbleStepGUI"
}
