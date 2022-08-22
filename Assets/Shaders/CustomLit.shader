Shader "Custom/CustomLit"
{
    Properties
    { }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #define MOCK_DATA
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS               : TEXCOORD1;
                float3 normalWS                 : TEXCOORD2;
            };            
            
            Varyings vert(Attributes IN)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

                output.positionHCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                
                return output;
            }

            void InitializeInputData(Varyings input, out InputData inputData)
            {
                inputData = (InputData)0;
                
                inputData.normalWS = input.normalWS;
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
            }

            void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                
            }

            half4 UniversalFragmentPBRCustom(InputData inputData, SurfaceData surfaceData)
            {
#if defined(MOCK_DATA)
                surfaceData.albedo = half4(0.5f, 0.0f, 0.0f, 1.0f);
                surfaceData.metallic = 0.0f;
                surfaceData.specular = half3(0.0f, 0.0f, 0.0f);
                surfaceData.smoothness = 1.0f;
                surfaceData.alpha = 0.0f;
#endif
                BRDFData brdfData;
                InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);
                
                // half4 shadowMask = CalculateShadowMask(inputData);
                half4 shadowMask = half4(1,1,1,1); 

                 AmbientOcclusionFactor aoFactor;
                // aoFactor = CreateAmbientOcclusionFactor(inputData.normalizedScreenSpaceUV, surfaceData.occlusion);

#if defined(MOCK_DATA)
                aoFactor.directAmbientOcclusion = 1;
                aoFactor.indirectAmbientOcclusion = 1;
#endif

                // Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
                Light mainLight = GetMainLight();
                
#if defined(MOCK_DATA)
                inputData.bakedGI = half3(0.0f, 0.0f, 0.0f); 
                surfaceData.emission = half3(0.0f, 0.0f, 0.0f);
#endif
                LightingData lightingData = CreateLightingData(inputData, surfaceData);
                bool specularHighlightsOff = false;

                BRDFData brdfDataClearCoat;
#if defined(MOCK_DATA)
                brdfDataClearCoat = (BRDFData)0;
                surfaceData.clearCoatMask = 1.0f;
#endif
                
                lightingData.mainLightColor = LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                              mainLight,
                                                              inputData.normalWS, inputData.viewDirectionWS,
                                                              surfaceData.clearCoatMask, specularHighlightsOff);
#if defined(MOCK_DATA)
                lightingData.giColor = half4(0.0f, 0.0f, 0.0f, 0.0f);
                lightingData.additionalLightsColor = half4(0.0f, 0.0f, 0.0f, 0.0f);
                lightingData.vertexLightingColor = half4(0.0f, 0.0f, 0.0f, 0.0f);
                lightingData.emissionColor = half4(0.0f, 0.0f, 0.0f, 0.0f);
#endif
                return CalculateFinalColor(lightingData, surfaceData.alpha);
            }
            
            void frag(Varyings input, out half4 outColor : SV_Target0)
            {
                SurfaceData surfaceData;
                // InitializeStandardLitSurfaceData(input.uv, surfaceData);
                
                InputData inputData;
                InitializeInputData(input, inputData);

                half4 color = UniversalFragmentPBRCustom(inputData, surfaceData);
                color.a = 0.0f;
                outColor = color;
            }
            ENDHLSL
        }
    }
}