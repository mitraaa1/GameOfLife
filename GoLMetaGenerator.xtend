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
			
			«generateInitialGrid(model)»
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
	
	def generateInitialGrid(Model model) '''
		
		public static boolean[][] getInitialGrid() {
			«IF model.grid !== null»
			boolean[][] grid = new boolean[«model.grid.width + 2»][«model.grid.height + 2»];
			
			// Initialize all cells to dead (false)
			for (int i = 0; i < grid.length; i++) {
				for (int j = 0; j < grid[0].length; j++) {
					grid[i][j] = false;
				}
			}
			
			// Set initial alive cells from DSL
			«FOR cell : model.cells»
			«generateCell(cell)»
			«ENDFOR»
			
			// Apply patterns
			«FOR pattern : model.patterns»
			«generatePattern(pattern)»
			«ENDFOR»
			
			return grid;
			«ELSE»
			// No grid defined, return default 50x50 grid
			return new boolean[52][52];
			«ENDIF»
		}
	'''
	
	def generateCell(gameoL.goLMeta.Cell cell) '''
		«IF cell.state.literal == 'alive'»
		grid[«cell.x + 1»][«cell.y + 1»] = true;  // Cell at («cell.x», «cell.y») alive
		«ENDIF»
	'''
	
	def generatePattern(gameoL.goLMeta.Pattern pattern) '''
		// Pattern «pattern.name» at («pattern.x», «pattern.y»)
		«FOR cellRef : pattern.cellSet.cells»
		grid[«pattern.x + cellRef.x + 1»][«pattern.y + cellRef.y + 1»] = true;
		«ENDFOR»
	'''
}