[{
	"resource": "/c:/Users/User/Documents/first_year_files/folder_for_jobs/LAWBOT/FINAL_VERSION/CLOSE_FINAL/LawBot/nextjs_web/LawbotWeb/src/components/modals/case-detail-modal.tsx",
	"owner": "typescript",
	"code": "2345",
	"severity": 8,
	"message": "Argument of type '{ confidence: number; riskLevel: string; prescribedOutcome: string; estimatedTime: string; recommendations: string[]; keyIndicators: { label: string; value: number; color: string; }[]; dataSourcesUsed: string[]; }' is not assignable to parameter of type 'SetStateAction<{ confidence: number; riskLevel: string; predictedOutcome: string; estimatedTime: string; recommendations: string[]; keyIndicators: { label: string; value: number; color: string; }[]; dataSourcesUsed: string[]; }>'.\n  Property 'predictedOutcome' is missing in type '{ confidence: number; riskLevel: string; prescribedOutcome: string; estimatedTime: string; recommendations: string[]; keyIndicators: { label: string; value: number; color: string; }[]; dataSourcesUsed: string[]; }' but required in type '{ confidence: number; riskLevel: string; predictedOutcome: string; estimatedTime: string; recommendations: string[]; keyIndicators: { label: string; value: number; color: string; }[]; dataSourcesUsed: string[]; }'.",
	"source": "ts",
	"startLineNumber": 404,
	"startColumn": 33,
	"endLineNumber": 404,
	"endColumn": 57,
	"relatedInformation": [
		{
			"startLineNumber": 88,
			"startColumn": 5,
			"endLineNumber": 88,
			"endColumn": 21,
			"message": "'predictedOutcome' is declared here.",
			"resource": "/c:/Users/User/Documents/first_year_files/folder_for_jobs/LAWBOT/FINAL_VERSION/CLOSE_FINAL/LawBot/nextjs_web/LawbotWeb/src/components/modals/case-detail-modal.tsx"
		}
	],
	"origin": "extHost2"
},{
	"resource": "/c:/Users/User/Documents/first_year_files/folder_for_jobs/LAWBOT/FINAL_VERSION/CLOSE_FINAL/LawBot/nextjs_web/LawbotWeb/src/components/modals/case-detail-modal.tsx",
	"owner": "typescript",
	"code": "2322",
	"severity": 8,
	"message": "Type '{ isOpen: boolean; onClose: () => void; caseData: any; statusHistory: any[]; evidenceFiles: any[]; aiSummary: string; aiActionItems: { high: string[]; medium: string[]; low: string[]; }; aiKeyDetails: { financialImpact: string; victimProfile: string; evidenceAssessment: string; riskFactors: string; complexity: strin...' is not assignable to type 'IntrinsicAttributes & CaseAnalyticsModalProps'.\n  Property 'aiPredictiveAnalysis' does not exist on type 'IntrinsicAttributes & CaseAnalyticsModalProps'. Did you mean 'aiPrescriptiveAnalysis'?",
	"source": "ts",
	"startLineNumber": 3042,
	"startColumn": 9,
	"endLineNumber": 3042,
	"endColumn": 29,
	"origin": "extHost2"
}]