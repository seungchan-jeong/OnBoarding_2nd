Shader "ScanEffect/ScanEffect"
{
    Properties
    {
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5
        _TimeScale("Time Scale", Float) = 0.5

        // BlendMode
        _Surface("__surface", Float) = 0.0
        _Blend("__mode", Float) = 0.0
        _Cull("__cull", Float) = 2.0
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
    }

    SubShader
    {
        Tags {"RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="4.5"}
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull [_Cull]

        Pass
        {
            Name "Unlit"

            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAMODULATE_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

            #pragma vertex UnlitPassVertex
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            sampler2D _CameraDepthTexture;
            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
            float4 _BaseMap_ST;
            float _TimeScale;
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 positionNDC : TEXCOORD1;
            };
            
            Varyings UnlitPassVertex(Attributes input)
            {
                Varyings output;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.positionCS = vertexInput.positionCS;
                output.positionNDC = vertexInput.positionNDC;

                return output;
            }
            void frag(
                    Varyings input
                    , out half4 outColor : SV_Target0
                #ifdef _WRITE_RENDERING_LAYERS
                    , out float4 outRenderingLayers : SV_Target1
                #endif
                )
            {
                float xScale = length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x));
                float zScale = length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z));
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, float2(input.uv.x * xScale, input.uv.y * zScale));
                
                float depth01 = Linear01Depth(tex2Dproj(_CameraDepthTexture, input.positionNDC).r, _ZBufferParams);
                float time01 = fmod(_Time.y * _TimeScale, 1.0f);
                float distanceDepthAndTime = saturate(abs(depth01 - time01));

                outColor = half4(texColor.xyz, texColor.w * pow(1.0f - distanceDepthAndTime, 30.0f));
            }
            ENDHLSL
        }
    }
}
