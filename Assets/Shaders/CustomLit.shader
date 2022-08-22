Shader "Custom/CustomLit"
{
    Properties
    { 
        [ToggleOff] _Diffuse("Diffuse", Float) = 1.0
        [ToggleOff] _Specular("Specular", Float) = 1.0
        [ToggleOff] _Ambient("Ambient", Float) = 1.0
    }
    
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            
            #define MOCK_DATA
            
            #pragma shader_feature_local _Diffuse
            #pragma shader_feature_local _Specular
            #pragma shader_feature_local _Ambient
            
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

                inputData.positionWS = input.positionWS;
                inputData.normalWS = NormalizeNormalPerPixel(input.normalWS);
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
            }
            
            void InitializeStandardLitSurfaceData(out SurfaceData outSurfaceData)
            {
                outSurfaceData = (SurfaceData)0;
#if defined(MOCK_DATA)
                outSurfaceData.albedo = half4(0.5f, 0.0f, 0.0f, 1.0f);
                outSurfaceData.metallic = 0.0f;
                outSurfaceData.specular = half3(0.0f, 0.0f, 0.0f);
                outSurfaceData.smoothness = 1.0f;
                outSurfaceData.alpha = 0.0f;
                outSurfaceData.emission = half3(0.0f, 0.0f, 0.0f);
#endif
            }

            half3 LightingPhysicallyBasedCustom(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
            {
                half3 lightColor = light.color;
                half3 lightDirectionWS = light.direction;
                half3 lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;

                half NdotL = saturate(dot(normalWS, lightDirectionWS));
                half3 radiance = lightColor * (lightAttenuation * NdotL);
                half3 brdf = half3(0.0f, 0.0f, 0.0f);
#ifdef _Diffuse
                brdf += brdfData.diffuse;
#endif
#ifdef _Specular
                brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
#endif

                return brdf * radiance;
            }
            
            half4 UniversalFragmentPBRCustom(InputData inputData, SurfaceData surfaceData)
            {
                BRDFData brdfData;
                InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);
                
                half4 shadowMask = half4(1,1,1,1);
                AmbientOcclusionFactor aoFactor;
                aoFactor.directAmbientOcclusion = 1;
                aoFactor.indirectAmbientOcclusion = 1;
                
                Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
                LightingData lightingData = CreateLightingData(inputData, surfaceData);
                
                BRDFData brdfDataClearCoat = (BRDFData)0;
                lightingData.mainLightColor = LightingPhysicallyBasedCustom(brdfData, 
                                                              mainLight,
                                                              inputData.normalWS, inputData.viewDirectionWS);
#ifdef _Ambient 
                lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, 1.0f,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS);
#else
                lightingData.giColor = 0.0f;
#endif
                uint pixelLightCount = GetAdditionalLightsCount();
LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
                    lightingData.additionalLightsColor += LightingPhysicallyBasedCustom(brdfData, light,
                                                                              inputData.normalWS, inputData.viewDirectionWS);
LIGHT_LOOP_END
                
#if defined(MOCK_DATA)
                lightingData.vertexLightingColor = half4(0.0f, 0.0f, 0.0f, 0.0f);
                lightingData.emissionColor = half4(0.0f, 0.0f, 0.0f, 0.0f);
#endif
                return CalculateFinalColor(lightingData, surfaceData.alpha);
            }
            
            void frag(Varyings input, out half4 outColor : SV_Target0)
            {
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(surfaceData);
                
                InputData inputData;
                InitializeInputData(input, inputData);

                half4 color = UniversalFragmentPBRCustom(inputData, surfaceData);
                color.a = 0.0f;
                outColor = color;
            }
            ENDHLSL
        }
    }
    CustomEditor "CustomLit"
}