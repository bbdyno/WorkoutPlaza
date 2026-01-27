.PHONY: install clean help

# Default target
.DEFAULT_GOAL := help

# Tuist 설치 및 프로젝트 생성
install:
	@echo "📦 Installing dependencies..."
	tuist install
	@echo "🔨 Generating Xcode project..."
	tuist generate
	@echo "🧹 Removing 'Generate Project' scheme..."
	@rm -f "WorkoutPlaza.xcworkspace/xcshareddata/xcschemes/Generate Project.xcscheme"
	@echo "✅ Done! You can now open WorkoutPlaza.xcworkspace"

# 프로젝트 정리
clean:
	@echo "🧹 Cleaning generated files..."
	rm -rf WorkoutPlaza.xcodeproj
	rm -rf WorkoutPlaza.xcworkspace
	rm -rf Derived
	rm -rf .build
	@echo "✅ Clean complete!"

# 도움말
help:
	@echo "WorkoutPlaza Makefile Commands:"
	@echo ""
	@echo "  make install    - Run 'tuist install' and 'tuist generate'"
	@echo "  make clean      - Remove generated Xcode project files"
	@echo "  make help       - Show this help message"
	@echo ""
