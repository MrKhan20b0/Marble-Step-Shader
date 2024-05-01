Shader "Unlit/MarbleDepth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Contrast ("Contrast", Range(0, 100)) = 0.5
        _CamOffset ("Offset", Range(-1, 1)) = 0.5
        _CON2     ("Contrast2", Range(0, 1)) = 0.5
        _Steps     ("Steps", Range(0, 1000)) = 1
        _ColorOne ("ColorOne", Color) = (.25, .5, .5, 1)
        _ColorTwo ("ColorOne", Color) = (.25, .5, .5, 1)
        _Lines    ("LINEs", Range(0.0001, 0.1)) = 0.5
        _LineOffset    ("LINEs OFfset", Range(0.001, 0.5)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


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
                float  depth : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float  _Contrast;
            float  _CamOffset;
            float  _CON2;
            float  _Steps;
            float4 _ColorOne;
            float4 _ColorTwo;
            float _Lines;
            float _LineOffset;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 viewDir = UNITY_MATRIX_IT_MV[2].xyz * _CON2;
                o.depth = mul(UNITY_MATRIX_IT_MV, v.vertex * 0.5 + viewDir).z * _Contrast + _CamOffset;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 col;
                i.depth = round(i.depth * _Steps) / _Steps;
                col = _ColorOne * i.depth +  _ColorTwo * (1 - i.depth);
                return col;
            }
            ENDCG
        }
    }
}
