package gameoL.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import gameoL.goLMeta.Model
import gameoL.goLMeta.Rule
import gameoL.goLMeta.RuleKind
import gameoL.goLMeta.Operator
import gameoL.goLMeta.CellState

class GoLMetaGenerator extends AbstractGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		// Get the model from the resource
		for (obj : resource.allContents.toIterable) {
			if (obj instanceof Model) {
				val model = obj as Model
				val java = generateRulesOfLife(model)
				fsa.generateFile("GameOfLife/RulesOfLife.java", java)
			}
		}
	}
	
	def generateRulesOfLife(Model model) '''
		package GameOfLife;
		
		import java.awt.Point;
		import java.util.ArrayList;
		
		public class RulesOfLife {
			public static void computeSurvivors(boolean[][] gameBoard, ArrayList<Point> survivingCells) {
				// Iterate through the array, follow game of life rules
				for (int i=1; i<gameBoard.length-1; i++) {
					for (int j=1; j<gameBoard[0].length-1; j++) {
						int surrounding = 0;
						if (gameBoard[i-1][j-1]) { surrounding++; }
						if (gameBoard[i-1][j])   { surrounding++; }
						if (gameBoard[i-1][j+1]) { surrounding++; }
						if (gameBoard[i][j-1])   { surrounding++; }
						if (gameBoard[i][j+1])   { surrounding++; }
						if (gameBoard[i+1][j-1]) { surrounding++; }
						if (gameBoard[i+1][j])   { surrounding++; }
						if (gameBoard[i+1][j+1]) { surrounding++; }
						
						/* Generated rules from DSL */
						«FOR rule : model.rules»
						«generateRule(rule)»
						«ENDFOR»
					}
				}
			}
			
			public static ArrayList<Point> getInitialCells() {
				ArrayList<Point> cells = new ArrayList<Point>();
				«FOR cell : model.cells.filter[state == CellState.ALIVE]»
				cells.add(new Point(«cell.x», «cell.y»));  // Cell at («cell.x», «cell.y»)
				«ENDFOR»
				return cells;
			}
		}
	'''
	
	def generateRule(Rule rule) {
		val operator = convertOperator(rule.condition.operator)
		val value = rule.condition.value
		
		switch (rule.kind) {
			case RuleKind.BIRTH: '''
				/* Birth rule: if neighbors «rule.condition.operator.literal» «value» */
				if ((!gameBoard[i][j]) && (surrounding «operator» «value»)) {
					survivingCells.add(new Point(i-1, j-1));
				}
			'''
			case RuleKind.SURVIVAL: '''
				/* Survival rule: if neighbors «rule.condition.operator.literal» «value» */
				if ((gameBoard[i][j]) && (surrounding «operator» «value»)) {
					survivingCells.add(new Point(i-1, j-1));
				}
			'''
			case RuleKind.DEATH: '''
				/* Death rule: if neighbors «rule.condition.operator.literal» «value» */
				// Death is handled by not adding to survivingCells
			'''
		}
	}
	
	def convertOperator(Operator op) {
		switch (op) {
			case Operator.LT: '<'
			case Operator.EQ: '=='
			case Operator.GT: '>'
			default: '=='
		}
	}
}